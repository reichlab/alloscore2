#' Build a p/d/q/r function with parameters fixed
#'
#' @param ... parameter name-value pairs to be fixed in the returned function.
#'   Parameters not accepted by the target distribution function are ignored, so
#'   entire rows of a forecast data frame may be passed in.
#' @param dist distribution root name, such as `"norm"` or `"beta"`, or
#'   `"distfromq"` to interpolate a distribution through predictive quantiles.
#' @param type one of `"p"`, `"d"`, `"q"` or `"r"`.
#' @inheritParams add_pdqr_funs
#'
#' @return A function of one argument: a cdf (`"p"`), density (`"d"`), quantile
#'   function (`"q"`) or random generator (`"r"`).
#'
#' @examples
#' F <- pdqr_factory(mean = 5, sd = 2, dist = "norm", type = "p")
#' F(5)
#'
#' # a distribution interpolated through predictive quantiles
#' Q <- pdqr_factory(
#'   ps = c(0.25, 0.5, 0.75), qs = c(4, 5, 6),
#'   dist = "distfromq", type = "q"
#' )
#' Q(0.5)
#'
#' @export
pdqr_factory <- function(
  ...,
  dist,
  type,
  trans = NULL,
  trans_inv = NULL,
  transpars = NULL
) {
  pars <- list(...)
  pars <- pars[!is.na(pars)]
  if (dist == "distfromq") {
    if (!requireNamespace("distfromq", quietly = TRUE)) {
      cli::cli_abort(
        "Package {.pkg distfromq} is required to use {.val distfromq} distributions."
      )
    }
    funfac <- get(
      paste0("make_", type, "_fn"),
      envir = asNamespace("distfromq")
    )
    selected_pars <- pars[intersect(names(formals(funfac)), names(pars))]
    fun <- rlang::exec(funfac, !!!selected_pars)
  } else {
    statfun <- get(paste0(type, dist))
    selected_pars <- pars[intersect(names(formals(statfun)), names(pars))]
    fun <- purrr::partial(statfun, ... = , !!!selected_pars)
  }
  if (!is.null(trans)) {
    transpars <- c(
      pars[intersect(names(formals(trans)), names(pars))],
      transpars
    )
    if (type %in% c("q", "r")) {
      fun <- purrr::compose(
        purrr::partial(trans_inv, ... = , !!!transpars),
        fun
      )
    } else {
      fun <- purrr::compose(fun, purrr::partial(trans, ... = , !!!transpars))
    }
  }
  fun
}

#' Add list columns of p/d/q/r functions to a forecast data frame
#'
#' Given a data frame with one row per target, a `dist` column (or a `dist`
#' argument) naming a distribution, and columns for that distribution's
#' parameters, adds list columns holding the corresponding cdf, density,
#' quantile function and/or random generator. [allocate()] needs only the cdf
#' (`"p"`) and quantile function (`"q"`).
#'
#' @param df data frame with one row per target. It must have a column for each
#'   parameter required by the distribution functions named in a `dist` column
#'   or in the `dist` argument.
#' @param dist character vector of length 1 or `nrow(df)` giving distribution
#'   root names (or `"distfromq"`); required if `df` has no `dist` column.
#' @param types which of `"p"`, `"d"`, `"q"`, `"r"` to add.
#' @param trans function of an outcome `x` and parameters, pre-composed with the
#'   `p` and `d` functions. Use this for distributions whose support must be
#'   rescaled, such as a beta distribution on `[x_min, x_max]`.
#' @param trans_inv inverse of `trans`, post-composed with the `q` and `r`
#'   functions.
#' @param transpars parameters for `trans` and `trans_inv` that are not columns
#'   of `df`.
#' @param fnames names to give the added list columns.
#'
#' @return A tibble with the requested list columns added.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(
#'     target_names = c("a", "b"),
#'     dist = "norm",
#'     mean = c(5, 8),
#'     sd = c(1, 2)
#'   ),
#'   types = c("p", "q")
#' )
#' fc$F[[1]](5)
#'
#' @export
add_pdqr_funs <- function(
  df,
  dist = df$dist,
  trans = NULL,
  trans_inv = NULL,
  transpars = NULL,
  types = c("p", "d", "q", "r"),
  fnames = c(p = "F", d = "f", q = "Q", r = "r")
) {
  if (!"dist" %in% names(df)) {
    if (is.null(dist)) {
      cli::cli_abort(
        "Distributions must be specified via a {.field dist} column or the {.arg dist} argument."
      )
    }
    df[["dist"]] <- dist
  }
  if (!"trans" %in% names(df) && !is.null(trans)) {
    if (!is.list(trans)) {
      trans <- list(trans)
    }
    df[["trans"]] <- trans
  }
  if (!"trans_inv" %in% names(df) && !is.null(trans_inv)) {
    if (
      is.null(trans_inv) &&
        !is.null(trans) &&
        any(is.element(c("q", "r"), types))
    ) {
      cli::cli_abort(
        "An inverse transformation {.arg trans_inv} is required for {.val q} or {.val r} functions."
      )
    }
    if (!is.list(trans_inv)) {
      trans_inv <- list(trans_inv)
    }
    df[["trans_inv"]] <- trans_inv
  }
  for (type in types) {
    df[[fnames[[type]]]] <- purrr::pmap(df, pdqr_factory, type = type)
  }
  tibble::as_tibble(df)
}
