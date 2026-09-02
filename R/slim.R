#' Get the weights of an allocated data frame
#'
#' @param object an `allocated` object, as returned by [allocate()].
#' @param ... ignored.
#'
#' @return The named vector of weights used in the allocation.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
#'   types = c("p", "q")
#' )
#' weights(allocate(fc, K = 10))
#'
#' @export
weights.allocated <- function(object, ...) {
  attr(object, "w")
}

#' Drop the heavy list columns of an allocated data frame
#'
#' An `allocated` object carries the full lambda-iteration history and a closure
#' per target, which is far more than is needed to score many outcome vectors
#' against the same allocation. `slim()` keeps the budgets, the allocations and
#' the scores.
#'
#' @param adf an `allocated` object, as returned by [allocate()].
#' @param xdf_action whether to unnest the `xdf` column. The default unnests an
#'   unscored allocation and leaves a scored one nested.
#' @param id_cols additional columns to keep, such as a model name or origin
#'   time.
#' @param rm_score_fun_if_scored drop the per-target scoring closure from a
#'   scored data frame, where it is usually no longer needed.
#' @param rm_score_fun_if_not_scored drop the per-target scoring closure from an
#'   unscored data frame. Defaults to `FALSE`, since it is what
#'   [alloscore.slim()] scores with.
#'
#' @return A tibble of class `slim`, carrying the `gpl_df`, `w` and
#'   `target_col_name` attributes of `adf`.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
#'   types = c("p", "q")
#' )
#' slim(allocate(fc, K = c(10, 20)))
#'
#' @export
slim <- function(
  adf,
  xdf_action = c("default", "unnest", "nest"),
  id_cols = NULL,
  rm_score_fun_if_scored = TRUE,
  rm_score_fun_if_not_scored = FALSE
) {
  if (!is.null(id_cols)) {
    adf <- dplyr::relocate(adf, tidyselect::all_of(id_cols))
  }
  id_cols <- c(id_cols, "K", "xdf")
  xdf_action <- match.arg(xdf_action)
  drop_score_fun <- function(out) {
    dplyr::mutate(
      out,
      xdf = purrr::map(
        .data$xdf,
        function(xdf) dplyr::select(xdf, -tidyselect::any_of("score_fun"))
      )
    )
  }
  if (inherits(adf, "scored")) {
    out <- dplyr::select(
      adf,
      tidyselect::any_of(c(id_cols, "score_raw", "score_oracle", "score"))
    )
    if (rm_score_fun_if_scored) {
      out <- drop_score_fun(out)
    }
    if (xdf_action == "unnest") {
      out <- tidyr::unnest(out, "xdf")
    }
  } else {
    out <- dplyr::select(adf, tidyselect::any_of(id_cols))
    if (rm_score_fun_if_not_scored) {
      out <- drop_score_fun(out)
    }
    if (xdf_action != "nest") {
      out <- tidyr::unnest(out, "xdf")
    }
  }
  class(out) <- c("slim", class(adf))
  structure(
    out,
    gpl_df = attr(adf, "gpl_df"),
    w = attr(adf, "w"),
    target_col_name = attr(adf, "target_col_name")
  )
}
