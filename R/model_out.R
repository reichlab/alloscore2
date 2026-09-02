#' Convert hubverse model output into forecasts alloscore2 can allocate against
#'
#' Groups a hubverse model output table into allocation problems, turns each
#' target's predictive quantiles into a cdf and quantile function using
#' [distfromq::make_p_fn()] and [distfromq::make_q_fn()], and attaches the
#' observed outcomes from `oracle_output`.
#'
#' An allocation problem is a set of targets that share one budget.
#' `target_cols` names the task ID columns whose combinations enumerate those
#' targets; every other task ID column, together with `model_id`, defines the
#' *allocation unit*, and one allocation problem is solved per combination of
#' those. This mirrors the way a hubverse `compound_taskid_set` distinguishes
#' task IDs that vary within a group from those held constant.
#'
#' @param model_out_tbl a hubverse model output table containing a single
#'   `output_type`, which must be `"quantile"`.
#' @param oracle_output hubverse oracle output, holding the observed values in
#'   an `oracle_value` column. Optional when only allocating.
#' @param target_cols character vector naming the task ID columns whose
#'   combinations enumerate the targets that share a budget, for example
#'   `"location"`.
#'
#' @return A tibble with one row per allocation unit, the allocation unit
#'   columns, and a `forecasts` list column. Each element of `forecasts` is a
#'   tibble with one row per target holding the `target_cols`, a
#'   `target_names` key, the predictive quantile levels `ps` and values `qs`,
#'   the cdf `F` and quantile function `Q`, and -- when `oracle_output` was
#'   supplied -- the observed outcome `y`.
#'
#' @examplesIf requireNamespace("hubExamples", quietly = TRUE)
#' mot <- dplyr::filter(hubExamples::forecast_outputs, output_type == "quantile")
#' adf <- as_alloscore_df(
#'   mot,
#'   oracle_output = hubExamples::forecast_oracle_output,
#'   target_cols = "location"
#' )
#' adf
#' adf$forecasts[[1]]
#'
#' @export
as_alloscore_df <- function(model_out_tbl, oracle_output = NULL, target_cols) {
  validate_output_type(model_out_tbl)
  units <- resolve_allocation_unit(model_out_tbl, target_cols)
  target_cols <- units$target_cols
  allocation_unit <- units$allocation_unit

  if (!is.null(oracle_output)) {
    model_out_tbl <- validate_model_oracle_out(model_out_tbl, oracle_output)
  } else if (!inherits(model_out_tbl, "model_out_tbl")) {
    model_out_tbl <- hubUtils::as_model_out_tbl(model_out_tbl)
  }

  # a non-numeric output_type_id warns on coercion; the check below reports it
  dat <- suppressWarnings(dplyr::mutate(
    tibble::as_tibble(model_out_tbl),
    output_type_id = as.numeric(.data$output_type_id)
  ))
  if (anyNA(dat[["output_type_id"]])) {
    cli::cli_abort(
      "Some {.field output_type_id} values are not numeric quantile levels."
    )
  }

  # one row per target, holding that target's predictive quantiles
  key_cols <- c(allocation_unit, target_cols)
  dat <- dplyr::arrange(
    dat,
    dplyr::pick(tidyselect::all_of(key_cols)),
    .data$output_type_id
  )
  dup <- dplyr::filter(
    dplyr::count(
      dat,
      dplyr::pick(tidyselect::all_of(c(key_cols, "output_type_id")))
    ),
    .data$n > 1L
  )
  if (nrow(dup) > 0) {
    cli::cli_abort(c(
      "{.arg model_out_tbl} has {nrow(dup)} duplicated forecast{?s}.",
      "i" = "Each combination of {.val {key_cols}} and {.field output_type_id} must appear once."
    ))
  }

  nested <- dplyr::summarise(
    dplyr::group_by(dat, dplyr::pick(tidyselect::all_of(key_cols))),
    ps = list(.data$output_type_id),
    qs = list(.data$value),
    .groups = "drop"
  )

  if (!is.null(oracle_output)) {
    oracle <- tibble::as_tibble(oracle_output)
    if ("output_type" %in% colnames(oracle)) {
      oracle <- dplyr::filter(oracle, .data$output_type == "quantile")
      oracle <- dplyr::select(
        oracle,
        -tidyselect::any_of(c("output_type", "output_type_id"))
      )
    }
    join_cols <- intersect(key_cols, colnames(oracle))
    oracle <- dplyr::distinct(
      dplyr::select(oracle, tidyselect::all_of(c(join_cols, "oracle_value")))
    )
    nested <- dplyr::left_join(
      nested,
      oracle,
      by = join_cols,
      relationship = "many-to-one"
    )
    missing_rows <- which(is.na(nested[["oracle_value"]]))
    if (length(missing_rows) > 0) {
      cli::cli_abort(c(
        "{length(missing_rows)} forecast{?s} {?has/have} no matching value in \
         {.arg oracle_output}.",
        "i" = "Joined on {.val {join_cols}}."
      ))
    }
    nested <- dplyr::rename(nested, y = "oracle_value")
  }

  # build the cdf and quantile function for each target
  nested[["F"]] <- purrr::map2(
    nested[["ps"]],
    nested[["qs"]],
    function(ps, qs) distfromq::make_p_fn(ps = ps, qs = qs)
  )
  nested[["Q"]] <- purrr::map2(
    nested[["ps"]],
    nested[["qs"]],
    function(ps, qs) distfromq::make_q_fn(ps = ps, qs = qs)
  )
  nested[["target_names"]] <- make_target_key(nested, target_cols)

  out <- dplyr::summarise(
    dplyr::group_by(nested, dplyr::pick(tidyselect::all_of(allocation_unit))),
    forecasts = list(dplyr::pick(tidyselect::everything())),
    .groups = "drop"
  )
  # keep the target-level columns in a predictable order
  out[["forecasts"]] <- purrr::map(out[["forecasts"]], function(fc) {
    dplyr::relocate(
      fc,
      tidyselect::all_of(c(target_cols, "target_names")),
      tidyselect::any_of("y"),
      "ps",
      "qs",
      "F",
      "Q"
    )
  })
  structure(out, target_cols = target_cols, allocation_unit = allocation_unit)
}

#' Build a single character key naming each target
#'
#' @noRd
make_target_key <- function(dat, target_cols) {
  if (length(target_cols) == 1L) {
    return(as.character(dat[[target_cols]]))
  }
  do.call(
    paste,
    c(lapply(target_cols, function(col) as.character(dat[[col]])), sep = "|")
  )
}

#' Allocate a budget across hubverse model output
#'
#' Runs [allocate()] once per allocation unit of a hubverse model output table.
#' See [as_alloscore_df()] for how allocation units are determined.
#'
#' @inheritParams as_alloscore_df
#' @inheritParams allocate
#' @param w allocation weights: a scalar, a vector named by target, a vector
#'   ordered as the targets of each allocation problem, or the name of a column
#'   of `model_out_tbl` holding a per-target weight.
#' @param ... further arguments passed to [allocate()].
#'
#' @return A tibble with one row per allocation unit and value of `K`, holding
#'   the allocation unit columns and the columns returned by [allocate()]. Unlike
#'   [allocate()] this is a plain tibble rather than an `allocated` object, since
#'   each unit has its own loss functions and weights.
#'
#' @examplesIf requireNamespace("hubExamples", quietly = TRUE)
#' mot <- dplyr::filter(
#'   hubExamples::forecast_outputs,
#'   output_type == "quantile", reference_date == "2022-11-19", horizon == 0
#' )
#' allocate_model_out(mot, K = c(100, 500), target_cols = "location")
#'
#' @export
allocate_model_out <- function(
  model_out_tbl,
  K,
  target_cols,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  ...
) {
  adf <- as_alloscore_df(
    model_out_tbl,
    oracle_output = NULL,
    target_cols = target_cols
  )
  run_over_units(
    adf,
    function(forecasts, weights) {
      allocate(
        df = forecasts,
        K = K,
        target_names = "target_names",
        w = weights,
        kappa = kappa,
        alpha = alpha,
        g = g,
        ...
      )
    },
    w = w
  )
}

#' Score hubverse model output with an allocation scoring rule
#'
#' For each allocation unit of a hubverse model output table, allocates a budget
#' under the model's forecasts and scores the realized loss of that allocation
#' relative to the loss of an oracle that knew the observed outcomes. See
#' [as_alloscore_df()] for how allocation units are determined, and
#' [alloscore()] for the score itself.
#'
#' @inheritParams as_alloscore_df
#' @inheritParams allocate_model_out
#' @param against_oracle logical; if `TRUE`, scores relative to the oracle
#'   allocation are included.
#' @param summarize logical; if `TRUE`, average the scores over the columns
#'   named in `by`.
#' @param by character vector naming the columns to summarize by. Must be a
#'   subset of the allocation unit columns and `"K"`.
#'
#' @return A tibble of scores. Unsummarized, one row per allocation unit and
#'   value of `K`, with columns `K`, `score`, `score_raw`, `score_oracle`,
#'   `ytot` and a nested `xdf` of per-target detail. Summarized, one row per
#'   combination of `by` with the mean of each score.
#'
#' @examplesIf requireNamespace("hubExamples", quietly = TRUE)
#' mot <- dplyr::filter(hubExamples::forecast_outputs, output_type == "quantile")
#' scores <- alloscore_model_out(
#'   model_out_tbl = mot,
#'   oracle_output = hubExamples::forecast_oracle_output,
#'   K = c(500, 1000),
#'   target_cols = "location",
#'   by = c("model_id", "K")
#' )
#' scores
#'
#' @export
alloscore_model_out <- function(
  model_out_tbl,
  oracle_output,
  K,
  target_cols,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  against_oracle = TRUE,
  summarize = TRUE,
  by = c("model_id", "K"),
  ...
) {
  adf <- as_alloscore_df(
    model_out_tbl,
    oracle_output = oracle_output,
    target_cols = target_cols
  )
  allocation_unit <- attr(adf, "allocation_unit")

  scores <- run_over_units(
    adf,
    function(forecasts, weights) {
      a <- allocate(
        df = forecasts,
        K = K,
        target_names = "target_names",
        w = weights,
        kappa = kappa,
        alpha = alpha,
        g = g,
        ...
      )
      alloscore(
        a,
        y = rlang::set_names(forecasts[["y"]], forecasts[["target_names"]]),
        against_oracle = against_oracle
      )
    },
    w = w
  )

  score_cols <- intersect(
    c("score", "score_raw", "score_oracle", "ytot"),
    colnames(scores)
  )
  scores <- dplyr::relocate(
    scores,
    tidyselect::all_of(c(allocation_unit, "K", score_cols))
  )
  scores <- dplyr::select(
    scores,
    tidyselect::all_of(c(allocation_unit, "K", score_cols)),
    tidyselect::any_of("xdf")
  )

  if (!summarize) {
    return(scores)
  }
  valid_by <- c(allocation_unit, "K")
  unknown <- setdiff(by, valid_by)
  if (length(unknown) > 0) {
    cli::cli_abort(c(
      "{.arg by} names {length(unknown)} column{?s} that {?is/are} not available.",
      "x" = "Not available: {.val {unknown}}.",
      "i" = "Expected a subset of {.val {valid_by}}."
    ))
  }
  dplyr::summarise(
    dplyr::group_by(scores, dplyr::pick(tidyselect::all_of(by))),
    dplyr::across(tidyselect::all_of(score_cols), mean),
    .groups = "drop"
  )
}

#' Run an allocation or scoring function over each allocation unit
#'
#' @param adf output of [as_alloscore_df()].
#' @param fn a function of `forecasts` and `weights` returning a tibble.
#' @param w weights, as accepted by [allocate_model_out()].
#'
#' @return A tibble binding the allocation unit columns to each result.
#'
#' @noRd
run_over_units <- function(adf, fn, w) {
  allocation_unit <- attr(adf, "allocation_unit")
  results <- purrr::map(
    seq_len(nrow(adf)),
    function(i) {
      forecasts <- adf[["forecasts"]][[i]]
      weights <- resolve_weights(w, forecasts, forecasts[["target_names"]])
      res <- fn(forecasts, weights)
      unit <- adf[i, allocation_unit, drop = FALSE]
      dplyr::bind_cols(
        unit[rep(1L, nrow(res)), , drop = FALSE],
        tibble::as_tibble(res)
      )
    }
  )
  purrr::list_rbind(results)
}
