#' Score allocations against realized outcomes
#'
#' Allocates a budget under a set of forecasts and then scores the realized gpl
#' loss of that allocation, optionally relative to the loss of an oracle that
#' knew the outcomes in advance. The oracle-relative score is non-negative and
#' is zero for a perfect forecast.
#'
#' @param df a data frame of forecasts, an `allocated` object (as returned by
#'   [allocate()]), or a `slim` object (as returned by [slim()]). The method
#'   dispatched on determines which further arguments apply.
#' @param ... arguments passed to methods.
#'
#' @return A tibble of the form returned by [allocate()], with the class
#'   `scored` prepended and additional columns
#'   \describe{
#'     \item{components_raw}{the realized gpl loss at each target (inside `xdf`).}
#'     \item{score_raw}{the sum of `components_raw`.}
#'     \item{components_oracle}{the oracle's loss at each target (inside `xdf`).}
#'     \item{score_oracle}{the sum of `components_oracle`.}
#'     \item{components}{`components_raw - components_oracle` (inside `xdf`).}
#'     \item{score}{`score_raw - score_oracle`.}
#'     \item{ytot}{the total weighted outcome, `sum(w * y)`.}
#'   }
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(
#'     target_names = c("a", "b", "c"),
#'     dist = "norm",
#'     mean = c(5, 8, 12),
#'     sd = c(1, 2, 3)
#'   ),
#'   types = c("p", "q")
#' )
#' s <- alloscore(fc, y = c(4, 9, 11), K = c(10, 20))
#' s[, c("K", "score", "score_raw", "score_oracle")]
#'
#' @export
alloscore <- function(df = NULL, ...) {
  UseMethod("alloscore")
}

#' @describeIn alloscore Allocates and then scores, for forecasts supplied as a
#'   data frame or as individual arguments.
#'
#' @param y numeric vector of observed outcomes, one per target.
#' @param against_oracle logical; if `TRUE`, components and scores relative to
#'   the oracle allocation are included.
#' @param slim logical; if `TRUE`, drop the heavy list columns before scoring.
#'   See [slim()].
#' @inheritParams allocate
#'
#' @export
alloscore.default <- function(
  df = NULL,
  K,
  target_names = NA,
  y,
  F = NULL,
  Q = NULL,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  dg = NA,
  eps_K = .01,
  eps_lam = 1e-4,
  against_oracle = TRUE,
  slim = FALSE,
  ...
) {
  # allocate() handles validation and attribute assignment
  a <- allocate(
    df = df,
    target_names = target_names,
    F = F,
    Q = Q,
    w = w,
    K = K,
    kappa = kappa,
    alpha = alpha,
    g = g,
    dg = dg,
    eps_K = eps_K,
    eps_lam = eps_lam
  )
  y <- rlang::set_names(y, gpl(a)[[attr(a, "target_col_name")]])
  if (slim) {
    a <- slim(a)
  }
  alloscore(a, y = y, against_oracle = against_oracle)
}

#' @describeIn alloscore Scores an allocation that has already been computed.
#'
#' @export
alloscore.allocated <- function(df, y, against_oracle = TRUE, ...) {
  if (length(y) != length(df$x[[1]])) {
    cli::cli_abort(
      "{.arg y} has length {length(y)} but there are {length(df$x[[1]])} targets."
    )
  }
  w <- attr(df, "w")
  scored_df <- dplyr::mutate(
    df,
    xdf = purrr::map(.data$xdf, function(xdf) {
      dplyr::mutate(
        xdf,
        y = y,
        components_raw = purrr::map2_dbl(
          .data$score_fun,
          .data$y,
          function(score_fun, y) score_fun(y)
        )
      )
    }),
    ytot = purrr::map_dbl(.data$xdf, function(xdf) sum(w * xdf[["y"]])),
    score_raw = purrr::map_dbl(.data$xdf, function(xdf) {
      sum(xdf[["components_raw"]])
    })
  )
  scored_df <- dplyr::relocate(
    scored_df,
    "score_raw",
    "ytot",
    .after = "K"
  )

  if (against_oracle) {
    oracle_scores <- oracle_allocate(
      gpl(df),
      y = y,
      w = w,
      K = df$K,
      target_names = attr(df, "target_col_name")
    )
    oracle_scores <- alloscore(oracle_scores, y = y, against_oracle = FALSE)
    oracle_scores <- dplyr::mutate(
      oracle_scores,
      xdf = purrr::map(.data$xdf, function(xdf) {
        dplyr::rename(xdf, oracle = "x", components_oracle = "components_raw")
      })
    )
    oracle_scores <- dplyr::rename(
      oracle_scores,
      xdf_oracle = "xdf",
      score_oracle = "score_raw"
    )
    scored_df <- dplyr::left_join(
      scored_df,
      dplyr::select(oracle_scores, "K", "xdf_oracle", "score_oracle"),
      by = "K"
    )
    scored_df <- dplyr::mutate(
      scored_df,
      xdf = purrr::map2(
        .data$xdf,
        .data$xdf_oracle,
        function(xdf, xdf_oracle) {
          out <- dplyr::bind_cols(
            xdf,
            dplyr::select(xdf_oracle, "oracle", "components_oracle")
          )
          out <- dplyr::mutate(
            out,
            components = .data$components_raw - .data$components_oracle
          )
          dplyr::relocate(out, "oracle", .after = "y")
        }
      ),
      score = .data$score_raw - .data$score_oracle
    )
    scored_df <- dplyr::relocate(scored_df, "score", .after = "K")
    scored_df <- dplyr::relocate(
      scored_df,
      "score_oracle",
      .after = "score_raw"
    )
  }
  class(scored_df) <- c("scored", class(scored_df))
  scored_df
}

#' @describeIn alloscore Scores a slim allocation against many outcome vectors,
#'   for Monte Carlo work. Uses [oracle_alloscore_direct()] rather than a full
#'   oracle allocation.
#'
#' @param ys a list of named outcome vectors, whose names must match the target
#'   names of `df`.
#'
#' @export
alloscore.slim <- function(df, ys, against_oracle = TRUE, ...) {
  if (!inherits(df, "allocated")) {
    cli::cli_abort("{.arg df} must inherit from {.cls allocated}.")
  }
  if (!is.list(ys)) {
    ys <- list(ys)
  }
  consistent <- purrr::map_lgl(ys, function(y) {
    !is.null(names(y)) && identical(names(ys[[1]]), names(y))
  })
  if (!all(consistent)) {
    cli::cli_abort("{.arg ys} must be consistently named by their targets.")
  }
  target_col_name <- attr(df, "target_col_name")
  comp_base <- dplyr::select(
    df,
    tidyselect::all_of(c("K", target_col_name, "x"))
  )
  w <- weights(df)
  Ks <- unique(df$K)
  gpl_fns <- gpl(df)$gpl_loss_fun

  results <- purrr::map(
    seq_along(ys),
    function(i) {
      y <- ys[[i]]
      xdf <- comp_base
      xdf[["y"]] <- rep(y, length(Ks))
      xdf[["components_raw"]] <- purrr::map2_dbl(
        df[[target_col_name]],
        df[["score_fun"]],
        function(nm, fn) fn(y[nm])
      )
      if (against_oracle) {
        oracle_cols <- purrr::list_rbind(
          purrr::map(Ks, function(K) oracle_alloscore_direct(y, K, w, gpl_fns))
        )
        xdf <- dplyr::bind_cols(xdf, oracle_cols)
        xdf[["components"]] <- xdf[["components_raw"]] -
          xdf[["components_oracle"]]
        scores <- dplyr::summarise(
          dplyr::group_by(xdf, .data$K),
          ytot = sum(w * .data$y),
          score_raw = sum(.data$components_raw),
          score_oracle = sum(.data$components_oracle),
          score = sum(.data$components),
          .groups = "drop"
        )
      } else {
        scores <- dplyr::summarise(
          dplyr::group_by(xdf, .data$K),
          ytot = sum(w * .data$y),
          score_raw = sum(.data$components_raw),
          .groups = "drop"
        )
      }
      list(xdf = xdf, scores = scores)
    },
    .progress = TRUE
  )

  tibble::tibble(
    samp = as.character(seq_along(ys)),
    xdf = purrr::map(results, "xdf"),
    scores = purrr::map(results, "scores")
  )
}
