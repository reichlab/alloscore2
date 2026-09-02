#' Get the names of the task ID columns of a model output table
#'
#' @param model_out_tbl a hubverse model output table.
#'
#' @return A character vector of column names.
#'
#' @noRd
get_task_id_cols <- function(model_out_tbl) {
  non_task_cols <- c(
    "model_id",
    "output_type",
    "output_type_id",
    "value",
    "model_abbr",
    "team_abbr"
  )
  setdiff(colnames(model_out_tbl), non_task_cols)
}

#' Check that a model output table holds a single supported output type
#'
#' @param model_out_tbl a hubverse model output table.
#'
#' @return The single `output_type` present, invisibly.
#'
#' @noRd
validate_output_type <- function(model_out_tbl) {
  output_types <- unique(model_out_tbl[["output_type"]])
  if (length(output_types) != 1L) {
    cli::cli_abort(c(
      "{.arg model_out_tbl} must contain a single {.field output_type}, but it has \\
       {length(output_types)}: {.val {output_types}}.",
      "i" = "Filter to one output type before scoring."
    ))
  }
  if (!identical(output_types, "quantile")) {
    cli::cli_abort(c(
      "{.arg model_out_tbl} has {.field output_type} {.val {output_types}}, which is not supported.",
      "i" = "{.pkg alloscore2} currently supports only the {.val quantile} output type."
    ))
  }
  invisible(output_types)
}

#' Validate a model output table and its oracle output
#'
#' @param model_out_tbl a hubverse model output table.
#' @param oracle_output hubverse oracle output, holding the observed values in
#'   an `oracle_value` column.
#'
#' @return `model_out_tbl`, coerced to class `model_out_tbl` if it was not
#'   already.
#'
#' @noRd
validate_model_oracle_out <- function(model_out_tbl, oracle_output) {
  req_cols <- c("model_id", "output_type", "output_type_id", "value")
  missing_cols <- setdiff(req_cols, colnames(model_out_tbl))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "{.arg model_out_tbl} is missing required column{?s} {.val {missing_cols}}."
    )
  }
  if (!"oracle_value" %in% colnames(oracle_output)) {
    cli::cli_abort(
      "{.arg oracle_output} must have an {.field oracle_value} column."
    )
  }

  task_id_cols <- get_task_id_cols(model_out_tbl)
  join_cols <- intersect(task_id_cols, colnames(oracle_output))
  if (length(join_cols) == 0) {
    cli::cli_abort(
      "{.arg model_out_tbl} and {.arg oracle_output} have no task ID columns in common."
    )
  }
  expected_cols <- c(
    task_id_cols,
    "output_type",
    "output_type_id",
    "oracle_value"
  )
  unexpected_cols <- setdiff(colnames(oracle_output), expected_cols)
  if (length(unexpected_cols) > 0) {
    cli::cli_abort(
      "{.arg oracle_output} has {length(unexpected_cols)} unexpected column{?s} \\
       {.val {unexpected_cols}}; expected a subset of {.val {expected_cols}}."
    )
  }

  if (!inherits(model_out_tbl, "model_out_tbl")) {
    model_out_tbl <- hubUtils::as_model_out_tbl(model_out_tbl)
  }
  model_out_tbl
}

#' Validate `target_cols` and derive the allocation unit
#'
#' An allocation problem is a set of targets that share one budget. `target_cols`
#' names the task ID columns whose combinations enumerate those targets; the
#' allocation unit is everything else, following the same logic as a hubverse
#' `compound_taskid_set`.
#'
#' @param model_out_tbl a hubverse model output table.
#' @param target_cols character vector of task ID columns identifying targets
#'   that share a budget.
#'
#' @return A list with elements `target_cols` and `allocation_unit`.
#'
#' @noRd
resolve_allocation_unit <- function(model_out_tbl, target_cols) {
  if (
    missing(target_cols) || is.null(target_cols) || length(target_cols) == 0
  ) {
    cli::cli_abort(c(
      "{.arg target_cols} must be supplied.",
      "i" = "It names the task ID columns whose combinations enumerate the targets
             that share a budget, for example {.code target_cols = \"location\"}."
    ))
  }
  task_id_cols <- get_task_id_cols(model_out_tbl)
  unknown <- setdiff(target_cols, task_id_cols)
  if (length(unknown) > 0) {
    cli::cli_abort(c(
      "{.arg target_cols} must name task ID columns of {.arg model_out_tbl}.",
      "x" = "Not a task ID column: {.val {unknown}}.",
      "i" = "Available task ID columns: {.val {task_id_cols}}."
    ))
  }
  allocation_unit <- c("model_id", setdiff(task_id_cols, target_cols))
  list(target_cols = target_cols, allocation_unit = allocation_unit)
}

#' Resolve allocation weights against the targets of one allocation problem
#'
#' @param w scalar, vector, or the name of a column of `model_out_tbl`.
#' @param forecasts the target-level tibble for one allocation unit.
#' @param target_key character vector naming each target.
#'
#' @return A numeric vector of weights, one per target.
#'
#' @noRd
resolve_weights <- function(w, forecasts, target_key) {
  n <- length(target_key)
  if (is.character(w) && length(w) == 1L) {
    if (!w %in% colnames(forecasts)) {
      cli::cli_abort(
        "{.arg w} names column {.val {w}}, which is not present in {.arg model_out_tbl}."
      )
    }
    return(forecasts[[w]])
  }
  if (!is.numeric(w)) {
    cli::cli_abort(
      "{.arg w} must be numeric or the name of a column of {.arg model_out_tbl}."
    )
  }
  if (length(w) == 1L && is.null(names(w))) {
    return(rep(w, n))
  }
  if (!is.null(names(w))) {
    missing_targets <- setdiff(target_key, names(w))
    if (length(missing_targets) > 0) {
      cli::cli_abort(
        "{.arg w} has no entry for target{?s} {.val {missing_targets}}."
      )
    }
    return(unname(w[target_key]))
  }
  if (length(w) != n) {
    cli::cli_abort(
      "{.arg w} has length {length(w)} but there are {n} targets; supply a scalar, a \\
       named vector, or a vector of length {n}."
    )
  }
  w
}
