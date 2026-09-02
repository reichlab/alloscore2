#' Convert newsvendor parameters to `kappa` and `alpha`
#'
#' @param ax wholesale cost per unit stocked.
#' @param ay unused; retained for symmetry with the source parameterization.
#' @param a_minus cost of revenue lost per unit of unmet demand.
#' @param a_plus cost incurred per unit left over.
#'
#' @return A data frame with columns `kappa` and `alpha`, suitable for use
#'   inside [dplyr::mutate()].
#'
#' @examples
#' stdize_news_params(ax = 4, a_minus = 7, a_plus = 1)
#'
#' @export
stdize_news_params <- function(ax, ay = NULL, a_minus, a_plus) {
  data.frame(
    kappa = as.double(a_plus + a_minus),
    alpha = (a_minus - ax) / (a_plus + a_minus)
  )
}

#' Convert over/under-prediction costs to `kappa` and `alpha`
#'
#' @param O cost incurred when the allocation exceeds the outcome.
#' @param U cost incurred when the outcome exceeds the allocation.
#'
#' @return A data frame with columns `kappa` and `alpha`.
#'
#' @examples
#' stdize_ou_params(O = 1, U = 3)
#'
#' @export
stdize_ou_params <- function(O, U) {
  data.frame(
    kappa = O + U,
    alpha = U / (O + U)
  )
}

#' Convert meteorologist parameters to `kappa` and `alpha`
#'
#' @param C marginal cost per unit of recommended protection.
#' @param L marginal loss due to under-provision of needed resources.
#'
#' @return A data frame with columns `kappa` and `alpha`.
#'
#' @examples
#' stdize_met_params(C = 2, L = 10)
#'
#' @export
stdize_met_params <- function(C, L) {
  data.frame(
    kappa = L,
    alpha = 1 - C / L
  )
}
