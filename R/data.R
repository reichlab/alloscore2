#' Multiproduct newsboy data with Normal demand
#'
#' Data transcribed from Table 2 of Zhang, Xu and Hua (2009), used there with a
#' budget of `K = 2500` and the unit cost `c` as the allocation weight. The
#' `Opt` column holds the published optimal solution, which makes this dataset
#' an external check on [allocate()].
#'
#' @format A data frame with 17 rows and 9 columns:
#' \describe{
#'   \item{Product}{product number.}
#'   \item{v}{cost of revenue lost per unit not stocked.}
#'   \item{h}{cost incurred per unit left over.}
#'   \item{c}{cost per unit.}
#'   \item{mu}{mean of demand.}
#'   \item{sigma}{standard deviation of demand.}
#'   \item{q_zxh}{the `(v - c) / (h + v)` quantile of the demand distribution,
#'     as given by Zhang, Xu and Hua.}
#'   \item{GIM}{solution of Abdel-Malek and Montanari (2005a).}
#'   \item{Opt}{optimal solution reported by Zhang, Xu and Hua.}
#' }
#'
#' @source B. Zhang, X. Xu, and Z. Hua, "A binary solution method for the
#'   multiproduct newsboy problem with budget constraint," Int. J. Prod. Econ.,
#'   vol. 117, no. 1, pp. 136-141, 2009.
#'
#' @seealso [zxh_tab3] for the Beta-demand example.
"zxh_tab2"

#' Multiproduct newsboy data with Beta demand
#'
#' Data transcribed from Table 3 of Zhang, Xu and Hua (2009), used there with a
#' budget of `K = 6500` and the unit cost `c` as the allocation weight. The
#' demand distributions are Beta distributions rescaled onto
#' `[x_min, x_max]`, so working with them requires the `trans` and `trans_inv`
#' arguments of [add_pdqr_funs()].
#'
#' @format A data frame with 6 rows and 11 columns:
#' \describe{
#'   \item{Product}{product number.}
#'   \item{v}{cost of revenue lost per unit not stocked.}
#'   \item{h}{cost incurred per unit left over.}
#'   \item{c}{cost per unit.}
#'   \item{x_min}{lower bound of the demand distribution's support.}
#'   \item{x_max}{upper bound of the demand distribution's support.}
#'   \item{Balpha}{the `shape1` parameter of the demand distribution.}
#'   \item{Bbeta}{the `shape2` parameter of the demand distribution.}
#'   \item{q_zxh}{the `(v - c) / (h + v)` quantile of the demand distribution,
#'     as given by Zhang, Xu and Hua.}
#'   \item{GIM}{solution of Abdel-Malek and Montanari (2005a).}
#'   \item{Opt}{optimal solution reported by Zhang, Xu and Hua.}
#' }
#'
#' @source B. Zhang, X. Xu, and Z. Hua, "A binary solution method for the
#'   multiproduct newsboy problem with budget constraint," Int. J. Prod. Econ.,
#'   vol. 117, no. 1, pp. 136-141, 2009.
#'
#' @seealso [zxh_tab2] for the Normal-demand example.
"zxh_tab3"
