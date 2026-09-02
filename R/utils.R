#' Get a function of `x` from a string
#'
#' @param func a string giving an expression in the variable `x`, e.g. `"log(x)"`.
#'
#' @return A function of a single argument `x`.
#'
#' @noRd
get_function <- function(func) {
  if (!grepl("\\bx\\b", func)) {
    cli::cli_abort(
      "Variable {.var x} must be used in the function string {.val {func}}."
    )
  }
  # fast paths for the common increment functions
  if (func == "x") {
    return(function(x) x)
  }
  if (func == "log(x)") {
    return(function(x) log(x))
  }
  if (func == "exp(x)") {
    return(function(x) exp(x))
  }
  func_expr <- parse(text = func)
  function(x) eval(func_expr, envir = list(x = x))
}

#' Get the derivative of a function of `x` entered as a string
#'
#' Uses [stats::D()] for symbolic differentiation, with fast paths for the
#' increment functions used most often.
#'
#' @inheritParams get_function
#'
#' @return A function of a single argument `x` giving the derivative of `func`.
#'
#' @noRd
get_derivative <- function(func) {
  if (!grepl("\\bx\\b", func)) {
    cli::cli_abort(
      "Variable {.var x} must be used in the function string {.val {func}}."
    )
  }
  if (func == "x") {
    return(function(x) 1)
  }
  if (func == "log(x)") {
    return(function(x) 1 / x)
  }
  if (func == "exp(x)") {
    return(function(x) exp(x))
  }
  der_expr <- D(parse(text = func), "x")
  function(x) eval(der_expr, envir = list(x = x))
}

#' Resolve the derivative of an increment function
#'
#' Honours a user-supplied `dg` and otherwise differentiates `g`. Unlike the
#' original alloscore, a supplied `dg` is not silently discarded.
#'
#' @param g increment function, as a string or a function.
#' @param dg derivative of `g`, or `NULL` to derive it from `g`.
#'
#' @return A function of a single argument `x`.
#'
#' @noRd
resolve_dg <- function(g = "x", dg = NULL) {
  if (rlang::is_function(dg)) {
    return(dg)
  }
  if (is.character(dg) && length(dg) == 1L && !is.na(dg)) {
    return(get_function(dg))
  }
  if (rlang::is_function(g)) {
    cli::cli_abort(c(
      "Cannot derive {.arg dg} from a {.cls function} {.arg g}.",
      "i" = "Supply {.arg g} as a string (e.g. {.val log(x)}) or supply {.arg dg} directly."
    ))
  }
  get_derivative(g)
}

#' Is a value "empty" for the purposes of argument resolution?
#'
#' @noRd
is_empty_arg <- function(v) {
  if (is.null(v)) {
    return(TRUE)
  }
  if (length(v) != 1L || rlang::is_function(v)) {
    return(FALSE)
  }
  isTRUE(is.na(v))
}

#' Resolve allocation arguments against columns of a forecast data frame
#'
#' A pure replacement for the original `get_args_from_df()`, which worked by
#' `assign()`ing into its caller's environment. The three resolution rules are
#' unchanged:
#'
#' * an argument that has a non-`NULL` default in the caller is overwritten by a
#'   like-named column of `df`;
#' * an argument left `NULL` or `NA` is filled from a like-named column of `df`;
#' * an argument whose value is a length-1 string naming a column of `df` is
#'   replaced by that column (this is how `w = "c"` works).
#'
#' @param df a data frame of forecasts, one row per target.
#' @param vals named list of the current argument values.
#' @param has_default character vector naming those arguments that have a
#'   non-`NULL` default in the calling function.
#'
#' @return `vals`, updated. The names of the arguments that were taken from
#'   `df` are returned in the `"args_from_df"` attribute.
#'
#' @noRd
resolve_df_args <- function(df, vals, has_default = character()) {
  out <- vals
  nms <- names(vals)

  # (a) arguments with non-NULL defaults are overridden by like-named columns
  replacements <- intersect(intersect(has_default, nms), names(df))
  for (nm in replacements) {
    out[[nm]] <- df[[nm]]
  }

  # (b) arguments still empty are supplied from like-named columns
  empty_arg_names <- nms[vapply(out, is_empty_arg, logical(1))]
  supplied_by_df <- intersect(empty_arg_names, names(df))
  for (nm in supplied_by_df) {
    out[[nm]] <- df[[nm]]
  }

  # (c) an argument whose value names a column of df is replaced by that column
  string_args <- character()
  for (nm in setdiff(nms, empty_arg_names)) {
    val <- out[[nm]]
    if (is.character(val) && length(val) == 1L && val %in% names(df)) {
      out[[nm]] <- df[[val]]
      string_args <- c(string_args, nm)
    }
  }

  attr(out, "args_from_df") <- unique(c(
    replacements,
    supplied_by_df,
    string_args
  ))
  out
}

#' Find an approximate root of a decreasing function, biased to the left
#'
#' Where `f` has a flat stretch at zero -- which happens when the predictive
#' distribution has a point mass -- we want the left-hand end of that stretch.
#'
#' @param point_mass_window distance to step to the left in order to find an
#'   approximate root with a non-negative value.
#' @inheritParams stats::uniroot
#'
#' @return Either the `root` element of [stats::uniroot()] applied to `f`, or a
#'   point slightly to its left.
#'
#' @noRd
unirootL <- function(f, lower, upper, point_mass_window) {
  u <- uniroot(f = f, upper = upper, lower = lower)
  if (u$f.root >= 0) {
    return(u$root)
  }
  new_root <- u$root - point_mass_window
  if (new_root <= lower) {
    return(lower)
  }
  if (f(new_root) < 0) {
    cli::cli_abort(c(
      "Point mass window too narrow.",
      "i" = "Increase {.arg point_mass_window} (currently {.val {point_mass_window}})."
    ))
  }
  new_root
}
