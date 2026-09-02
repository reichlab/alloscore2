#' Allocate as an oracle that knows the observed outcomes
#'
#' Runs [allocate()] with degenerate predictive distributions that place all of
#' their probability on the observed outcomes, giving the allocation against
#' which a forecaster's allocation is scored. Because those distributions are
#' point masses, the objective is piecewise constant and
#' [post_process()] is always needed.
#'
#' @param gpl_df a `gpl_df` (see [new_gpl_df()]) or an `allocated` object, from
#'   which the loss parameters and weights are taken.
#' @param y observed outcomes, one per target.
#' @inheritParams allocate
#' @param ... further arguments passed to [allocate()].
#'
#' @return An `allocated` tibble; see [allocate()].
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
#'   types = c("p", "q")
#' )
#' a <- allocate(fc, K = 10)
#' oracle_allocate(a, y = c(4, 9), K = 10)$x
#'
#' @export
oracle_allocate <- function(gpl_df, y, K, w = 1, ...) {
  if (inherits(gpl_df, "allocated")) {
    w <- weights(gpl_df)
    gpl_df <- gpl(gpl_df)
  }
  # Keep the increment function, target names and loss parameters; drop the
  # columns allocate() would ignore. The oracle's loss uses kappa <- alpha with
  # alpha <- 1, so that only under-allocation is penalized.
  gpl_df <- dplyr::select(
    gpl_df,
    -tidyselect::any_of(c("O", "U", "offset", "gpl_loss_fun"))
  )
  gpl_df <- dplyr::mutate(gpl_df, kappa = .data$alpha, alpha = 1)
  allocate(
    df = gpl_df,
    w = w,
    F = purrr::map(y, function(y) function(x) 1 * (x >= y)),
    Q = purrr::map(y, function(y) function(p) y),
    K = K,
    eps_lam = .01, # a tighter tolerance buys nothing against point masses
    ...
  )
}

#' Find the oracle allocation directly
#'
#' A closed form for the oracle's allocation, avoiding the machinery of
#' [allocate()]. If the observed outcomes are affordable the oracle allocates
#' exactly those; otherwise it scales them down proportionally. Assumes all
#' targets share the same gpl parameters and that `g` is the identity.
#'
#' @inheritParams oracle_allocate
#' @inheritParams allocate
#'
#' @return A numeric vector of allocations.
#'
#' @examples
#' oracle_allocate_direct(y = c(3, 5), K = 4, w = 1)
#' oracle_allocate_direct(y = c(3, 5), K = 100, w = 1)
#'
#' @export
oracle_allocate_direct <- function(y, K, w) {
  if (sum(w * y) <= K) {
    y
  } else {
    y * K / sum(w * y)
  }
}

#' Find and score the oracle allocation directly
#'
#' @inheritParams oracle_allocate_direct
#' @param gpl_fns list of gpl loss functions, one per target.
#'
#' @return A tibble with columns `oracle` and `components_oracle`.
#'
#' @examples
#' oracle_alloscore_direct(
#'   y = c(3, 5), K = 4, w = 1,
#'   gpl_fns = list(gpl_loss_fun(alpha = 1), gpl_loss_fun(alpha = 1))
#' )
#'
#' @export
oracle_alloscore_direct <- function(y, K, w, gpl_fns) {
  oracle <- oracle_allocate_direct(y, K, w)
  components_oracle <- purrr::pmap_dbl(
    list(gpl_fns, oracle, y),
    function(fn, o, y) fn(o, y)
  )
  tibble::tibble(oracle = oracle, components_oracle = components_oracle)
}
