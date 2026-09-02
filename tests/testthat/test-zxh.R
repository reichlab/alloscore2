# External validation against published optima. Zhang, Xu and Hua (2009) report
# the optimal solution to each of these budget-constrained multiproduct newsboy
# problems in the `Opt` column, so these tests check `allocate()` against the
# literature rather than against either version of this package.

test_that("allocate reproduces ZXH Table 2 (Normal demand, K = 2500)", {
  ex <- zxh_norm_forecasts()
  a <- allocate(ex, w = "c", K = 2500, target_names = "Product")
  cmp <- dplyr::left_join(
    dplyr::select(ex, "Product", "c", "Opt"),
    a$xdf[[1]],
    by = "Product"
  )
  # ZXH report their solution to two decimal places, and their binary method is
  # itself an approximation, so agreement is to within a tenth of a unit
  expect_equal(cmp$x, cmp$Opt, tolerance = 1e-3, ignore_attr = TRUE)
  expect_lt(max(abs(cmp$x - cmp$Opt)), 0.1)
})

test_that("the ZXH Table 2 solution spends the budget and is sparse", {
  ex <- zxh_norm_forecasts()
  a <- allocate(ex, w = "c", K = 2500, target_names = "Product")
  cmp <- dplyr::left_join(
    dplyr::select(ex, "Product", "c", "Opt"),
    a$xdf[[1]],
    by = "Product"
  )
  # the budget is exhausted to within the default eps_K of 1%
  expect_equal(sum(cmp$c * cmp$x), 2500, tolerance = 0.01)
  # only 6 of the 17 products are stocked at all, and they are ZXH's 6
  expect_equal(sum(cmp$x > 1e-8), 6)
  expect_equal(cmp$x > 1e-8, cmp$Opt > 0)
})

test_that("our ZXH Table 2 objective is no worse than at the published optimum", {
  ex <- zxh_norm_forecasts()
  a <- allocate(ex, w = "c", K = 2500, target_names = "Product")
  cmp <- dplyr::left_join(
    dplyr::select(ex, "Product", "c", "Opt", "kappa", "alpha", "mean", "F"),
    a$xdf[[1]],
    by = "Product"
  )
  objective <- function(x_col) {
    sum(purrr::pmap_dbl(
      list(cmp$F, cmp$kappa, cmp$alpha, cmp$mean, cmp$c, cmp[[x_col]]),
      function(F, kappa, alpha, mean, c, x) {
        exp_gpl_loss_fun(
          F = F,
          kappa = kappa,
          alpha = alpha,
          offset = c * mean
        )(x)
      }
    ))
  }
  # our allocation spends marginally more than K, so it may beat ZXH's value
  expect_lte(objective("x"), objective("Opt") + 1e-6)
})

test_that("allocate reproduces ZXH Table 3 (Beta demand, K = 6500)", {
  ex <- zxh_beta_forecasts()
  a <- allocate(ex, w = "c", K = 6500, target_names = "Product")
  cmp <- dplyr::left_join(
    dplyr::select(ex, "Product", "c", "Opt", "x_min", "x_max"),
    a$xdf[[1]],
    by = "Product"
  )
  expect_equal(cmp$x, cmp$Opt, tolerance = 1e-3, ignore_attr = TRUE)
  expect_lt(max(abs(cmp$x - cmp$Opt)), 1)
  expect_equal(sum(cmp$c * cmp$x), 6500, tolerance = 0.01)
  # every product is stocked here, within its bounded support
  expect_true(all(cmp$x > 0))
  expect_true(all(cmp$x >= cmp$x_min))
  expect_true(all(cmp$x <= cmp$x_max))
})

test_that("the newsvendor reparameterization matches the critical quantile", {
  # ZXH's q_zxh column is the (v - c) / (h + v) quantile of demand, which is
  # exactly the alpha-quantile of our reparameterized loss
  ex <- zxh_norm_forecasts()
  q_ours <- purrr::map2_dbl(ex$Q, ex$alpha, function(Q, alpha) Q(alpha))
  expect_equal(q_ours, ex$q_zxh, tolerance = 1e-2)
})

test_that("an unbinding budget gives the unconstrained newsvendor solution", {
  # with no budget constraint each product is stocked at its critical quantile
  ex <- zxh_norm_forecasts()
  a <- allocate(ex, w = "c", K = 1e7, target_names = "Product")
  expect_true(a$qs_OK)
  expect_equal(unname(a$x[[1]]), ex$q_zxh, tolerance = 1e-2)
})
