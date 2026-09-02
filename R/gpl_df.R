#' Create a data frame of gpl loss functions and their parameters
#'
#' Recycles scalar arguments to length `N` and builds one gpl loss function per
#' target.
#'
#' @param N number of targets. If `NULL`, inferred from the longest argument.
#' @param target_names names of the targets, one per row.
#' @inheritParams gpl_loss_fun
#' @param dg derivative of `g`. Defaults to `NA`, in which case it is derived
#'   symbolically from `g` when needed.
#'
#' @return A tibble of class `gpl_df` with one row per target, columns for each
#'   loss parameter, and a `gpl_loss_fun` list column of loss functions.
#'
#' @examples
#' new_gpl_df(N = 3, alpha = c(0.5, 0.7, 0.9), target_names = c("a", "b", "c"))
#'
#' @export
new_gpl_df <- function(
  N = NULL,
  target_names = NA,
  g = "x",
  dg = NA,
  kappa = 1,
  alpha = 1,
  O = NA,
  U = NA,
  offset = 0
) {
  args <- list(
    g = g,
    dg = dg,
    target_names = target_names,
    kappa = kappa,
    alpha = alpha,
    O = O,
    U = U,
    offset = offset
  )
  nms <- names(args)
  if (is.null(N)) {
    N <- max(purrr::map_int(args, length))
  }
  for (i in seq_along(args)) {
    if (!length(args[[i]]) %in% c(1L, N)) {
      cli::cli_abort("{.arg {nms[i]}} must be of length 1 or {N}.")
    }
  }
  tibble_args <- purrr::map(nms, function(nm) {
    val <- args[[nm]]
    if (is.list(val)) {
      if (length(val) == 1L) rep(val, N) else val
    } else {
      if (length(val) == N) val else rep(val, N)
    }
  })
  names(tibble_args) <- nms
  gpl <- tibble::as_tibble(tibble_args)
  gpl[["gpl_loss_fun"]] <- purrr::pmap(
    list(
      g = gpl[["g"]],
      kappa = gpl[["kappa"]],
      alpha = gpl[["alpha"]],
      O = gpl[["O"]],
      U = gpl[["U"]],
      offset = gpl[["offset"]]
    ),
    gpl_loss_fun
  )
  structure(gpl, class = c("gpl_df", class(gpl)))
}

#' Create a list of derivatives of expected gpl losses from a `gpl_df`
#'
#' @param df a `gpl_df`, as created by [new_gpl_df()].
#' @param F list of predictive cdfs, one per row of `df`.
#'
#' @return A list of functions of an allocation `x`, one per target.
#'
#' @examples
#' gdf <- new_gpl_df(N = 2, alpha = 0.5)
#' dexp_gpl_df(gdf, F = list(pnorm, pnorm))
#'
#' @export
dexp_gpl_df <- function(df, F) {
  if (!inherits(df, "gpl_df")) {
    cli::cli_abort("{.arg df} must be a {.cls gpl_df}.")
  }
  if (nrow(df) != length(F)) {
    cli::cli_abort(
      "Need the same number of targets ({nrow(df)}) and distributions ({length(F)})."
    )
  }
  args <- df[,
    intersect(names(df), names(formals(dexp_gpl_loss))),
    drop = FALSE
  ]
  args[["F"]] <- F
  purrr::pmap(args, dexp_gpl_loss)
}

#' Create marginal expected benefit functions for a `gpl_df`
#'
#' The marginal expected benefit of allocating to target `i` is
#' \deqn{\Lambda_i(x) = -\frac{1}{w_i}\frac{d}{dx} E L_i(x, Y_i)
#'       = \frac{\kappa_i}{w_i} g'(x) (\alpha_i - F_i(x)),}
#' a decreasing function of `x`. [allocate()] equalizes it across targets.
#'
#' @param w weights (costs per unit allocated) used in the budget constraint.
#' @inheritParams dexp_gpl_df
#'
#' @return A list of functions of an allocation `x`, one per target.
#'
#' @examples
#' gdf <- new_gpl_df(N = 2, alpha = 0.5)
#' meb <- meb_gpl_df(gdf, F = list(pnorm, pnorm), w = 1)
#' meb[[1]](0)
#'
#' @export
meb_gpl_df <- function(df, F, w) {
  if (!inherits(df, "gpl_df")) {
    cli::cli_abort("{.arg df} must be a {.cls gpl_df}.")
  }
  if (!is.numeric(w)) {
    cli::cli_abort("{.arg w} must be numeric.")
  }
  if (!length(w) %in% c(1L, nrow(df))) {
    cli::cli_abort(
      "Need the same number of targets ({nrow(df)}) and weights ({length(w)})."
    )
  }
  df[["kappa"]] <- -(1 / w) * df[["kappa"]]
  dexp_gpl_df(df, F = F)
}

#' Get the gpl loss data frame of an allocation
#'
#' @param adf an object of class `allocated`, as returned by [allocate()].
#'
#' @return The `gpl_df` stored in the `"gpl_df"` attribute of `adf`.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
#'   types = c("p", "q")
#' )
#' gpl(allocate(fc, K = 10))
#'
#' @export
gpl <- function(adf) {
  if (!inherits(adf, "allocated")) {
    cli::cli_abort("{.arg adf} must be an {.cls allocated} object.")
  }
  attr(adf, "gpl_df")
}
