#' Normalize an over/under-prediction parameterization to `kappa` and `alpha`
#'
#' The gpl loss admits two equivalent parameterizations: a scale/level pair
#' (`kappa`, `alpha`) and an over/under cost pair (`O`, `U`), related by
#' `O = kappa * (1 - alpha)` and `U = kappa * alpha`. Exactly one of `alpha` and
#' `U` must be supplied. This helper reduces the second parameterization to the
#' first so that everything downstream has a single code path.
#'
#' @param kappa scale factor.
#' @param alpha normalized loss when the outcome `y` exceeds the allocation `x`.
#' @param O cost incurred when the allocation `x` exceeds the outcome `y`;
#'   equals `kappa * (1 - alpha)`.
#' @param U cost incurred when the outcome `y` exceeds the allocation `x`;
#'   equals `kappa * alpha`.
#'
#' @return A list with elements `kappa` and `alpha`.
#'
#' @noRd
normalize_gpl_params <- function(kappa = 1, alpha = NA, O = NA, U = NA) {
  if (!xor(is.na(U), is.na(alpha))) {
    cli::cli_abort(
      "Either {.arg U} or {.arg alpha} must be specified, but not both."
    )
  }
  if (!is.na(U)) {
    if (is.na(O)) {
      cli::cli_abort("{.arg O} must be specified alongside {.arg U}.")
    }
    if (O + U == 0) {
      cli::cli_abort("{.arg O} and {.arg U} must not sum to zero.")
    }
    return(list(kappa = O + U, alpha = U / (O + U)))
  }
  list(kappa = kappa, alpha = alpha)
}

#' Basic g-linear loss for under-prediction of an outcome
#'
#' @param g a non-decreasing increment function, supplied either as a function
#'   or as a string in the variable `x` such as `"log(x)"`.
#'
#' @return A function of an allocation `x` and an outcome `y` that penalizes
#'   only under-prediction.
#'
#' @examples
#' ul <- under_loss()
#' ul(x = 1, y = 3)
#' ul(x = 3, y = 1)
#'
#' @export
under_loss <- function(g = function(u) u) {
  if (is.character(g)) {
    g <- get_function(g)
  }
  function(x, y) pmax(g(y) - g(x), 0)
}

#' Basic g-linear loss for over-prediction of an outcome
#'
#' @inheritParams under_loss
#'
#' @return A function of an allocation `x` and an outcome `y` that penalizes
#'   only over-prediction.
#'
#' @examples
#' ol <- over_loss()
#' ol(x = 3, y = 1)
#' ol(x = 1, y = 3)
#'
#' @export
over_loss <- function(g = function(u) u) {
  if (is.character(g)) {
    g <- get_function(g)
  }
  function(x, y) pmax(g(x) - g(y), 0)
}

#' Expected g-linear loss for under-prediction of a random outcome
#'
#' @param dg derivative of the increment function `g`.
#' @param F predictive cdf of the outcome.
#'
#' @return A function of an allocation `x` giving the expected g-linear loss of
#'   under-predicting an outcome distributed according to `F`.
#'
#' @examples
#' eul <- exp_under_loss(F = pnorm)
#' eul(0)
#'
#' @export
exp_under_loss <- function(dg = function(y) 1, F) {
  Vectorize(function(x) {
    integrate(
      f = function(y) (1 - F(y)) * dg(y),
      lower = x,
      upper = Inf,
      rel.tol = .001
    )$value
  })
}

#' Expected g-linear loss for over-prediction of a random outcome
#'
#' @inheritParams exp_under_loss
#'
#' @return A function of an allocation `x` giving the expected g-linear loss of
#'   over-predicting an outcome distributed according to `F`.
#'
#' @examples
#' eol <- exp_over_loss(F = pnorm)
#' eol(0)
#'
#' @export
exp_over_loss <- function(dg = function(y) 1, F) {
  Vectorize(function(x) {
    integrate(
      f = function(y) F(y) * dg(y),
      lower = -Inf,
      upper = x,
      rel.tol = .001
    )$value
  })
}

#' Derivative of the expected under-prediction loss
#'
#' @inheritParams under_loss
#' @inheritParams exp_under_loss
#' @param dg derivative of `g`; if `NULL` or `NA` it is derived from `g`.
#'
#' @return A function of an allocation `x`.
#'
#' @examples
#' dexp_under_loss(F = pnorm)(0)
#'
#' @export
dexp_under_loss <- function(g = "x", dg = NULL, F) {
  dg <- resolve_dg(g, dg)
  function(x) dg(x) * (F(x) - 1)
}

#' Derivative of the expected over-prediction loss
#'
#' @inheritParams dexp_under_loss
#'
#' @return A function of an allocation `x`.
#'
#' @examples
#' dexp_over_loss(F = pnorm)(0)
#'
#' @export
dexp_over_loss <- function(g = "x", dg = NULL, F) {
  dg <- resolve_dg(g, dg)
  function(x) dg(x) * F(x)
}

#' Create a generalized piecewise linear (gpl) loss function
#'
#' The gpl loss of an allocation `x` against an outcome `y` is
#' \deqn{L(x, y) = \kappa[(1 - \alpha)(g(x) - g(y))_+ + \alpha (g(y) - g(x))_+] + \mathrm{offset}(y).}
#' With `g(x) = x` this is the pinball (quantile) loss at level `alpha`, scaled
#' by `kappa`. Despite the name it need not be piecewise linear, since `g` may
#' be any non-decreasing increment function.
#'
#' @inheritParams under_loss
#' @param kappa scale factor.
#' @param alpha normalized loss when the outcome `y` exceeds the allocation `x`.
#'   Exactly one of `alpha` and `U` must be supplied.
#' @param O cost incurred when the allocation `x` exceeds the outcome `y`;
#'   equals `kappa * (1 - alpha)`.
#' @param U cost incurred when the outcome `y` exceeds the allocation `x`;
#'   equals `kappa * alpha`.
#' @param offset a constant, or a function of `y`, added to the loss. The
#'   default of `0` gives a loss with `L(x, x) = 0`.
#'
#' @return A function of an allocation `x` and an outcome `y` giving the loss.
#'
#' @examples
#' # pinball loss at the median
#' L <- gpl_loss_fun(alpha = 0.5)
#' L(x = 1, y = 3)
#'
#' # the equivalent over/under-cost parameterization
#' L2 <- gpl_loss_fun(O = 0.5, U = 0.5)
#' L2(x = 1, y = 3)
#'
#' @export
gpl_loss_fun <- function(
  g = "x",
  kappa = 1,
  alpha = NA,
  O = NA,
  U = NA,
  offset = 0
) {
  if (is.character(g)) {
    g <- get_function(g)
  }
  pars <- normalize_gpl_params(kappa = kappa, alpha = alpha, O = O, U = U)
  gpl_base <- function(x, y) {
    pars$kappa *
      ((1 - pars$alpha) * over_loss(g)(x, y) + pars$alpha * under_loss(g)(x, y))
  }
  if (rlang::is_function(offset)) {
    function(x, y) gpl_base(x, y) + offset(y)
  } else {
    function(x, y) gpl_base(x, y) + offset
  }
}

#' Create an expected gpl loss function
#'
#' This is the per-target contribution to the objective minimized by
#' [allocate()].
#'
#' @inheritParams exp_under_loss
#' @param kappa scale factor.
#' @param alpha normalized loss when the outcome `y` exceeds the allocation `x`.
#'   Exactly one of `alpha` and `U` must be supplied.
#' @param O cost incurred when the allocation `x` exceeds the outcome `y`;
#'   equals `kappa * (1 - alpha)`.
#' @param U cost incurred when the outcome `y` exceeds the allocation `x`;
#'   equals `kappa * alpha`.
#' @param offset a constant added to the expected loss. Unlike
#'   [gpl_loss_fun()], a function-valued `offset` is not supported here, since
#'   its expectation would itself require integration.
#'
#' @return A function of an allocation `x` giving the expected loss with
#'   respect to the distribution `F`.
#'
#' @examples
#' Z <- exp_gpl_loss_fun(F = pnorm, alpha = 0.5)
#' Z(0)
#'
#' @export
exp_gpl_loss_fun <- function(
  dg = function(u) 1,
  F,
  kappa = 1,
  alpha = NA,
  O = NA,
  U = NA,
  offset = 0
) {
  pars <- normalize_gpl_params(kappa = kappa, alpha = alpha, O = O, U = U)
  if (rlang::is_function(offset)) {
    cli::cli_abort(c(
      "A function-valued {.arg offset} is not supported by {.fun exp_gpl_loss_fun}.",
      "i" = "Supply a constant, or take the expectation of the offset yourself."
    ))
  }
  function(x) {
    pars$kappa *
      ((1 - pars$alpha) *
        exp_over_loss(dg, F)(x) +
        pars$alpha * exp_under_loss(dg, F)(x)) +
      offset
  }
}

#' Derivative of the expected gpl loss
#'
#' For the linear increment function this is
#' \deqn{\kappa\, g'(x)\, (F(x) - \alpha),}
#' the quantity whose root gives the unconstrained optimal allocation.
#'
#' @inheritParams dexp_under_loss
#' @param kappa scale factor.
#' @param alpha normalized loss when the outcome `y` exceeds the allocation `x`.
#'   Exactly one of `alpha` and `U` must be supplied.
#' @param O cost incurred when the allocation `x` exceeds the outcome `y`;
#'   equals `kappa * (1 - alpha)`.
#' @param U cost incurred when the outcome `y` exceeds the allocation `x`;
#'   equals `kappa * alpha`.
#'
#' @return A function of an allocation `x` giving the derivative of the
#'   expected loss with respect to the distribution `F`.
#'
#' @examples
#' # zero at the median of the predictive distribution
#' dexp_gpl_loss(F = pnorm, alpha = 0.5)(0)
#'
#' @export
dexp_gpl_loss <- function(
  g = "x",
  dg = NULL,
  F,
  kappa = 1,
  alpha = NA,
  O = NA,
  U = NA
) {
  if (rlang::is_missing(F)) {
    cli::cli_abort("Predictive cdf {.arg F} is missing.")
  }
  dg <- resolve_dg(g, dg)
  pars <- normalize_gpl_params(kappa = kappa, alpha = alpha, O = O, U = U)
  kappa <- pars$kappa
  alpha <- pars$alpha
  # alpha == 1 means the over-prediction term drops out; treating it separately
  # avoids 0 * Inf when g'(x) is unbounded, as it is for g = log(x) at 0.
  if (isTRUE(alpha == 1)) {
    return(function(x) kappa * (alpha * dexp_under_loss(dg = dg, F = F)(x)))
  }
  function(x) {
    kappa *
      ((1 - alpha) *
        dexp_over_loss(dg = dg, F = F)(x) +
        alpha * dexp_under_loss(dg = dg, F = F)(x))
  }
}
