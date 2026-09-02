test_that("stdize_news_params converts newsvendor costs", {
  res <- stdize_news_params(ax = 4, a_minus = 7, a_plus = 1)
  expect_equal(res$kappa, 8)
  expect_equal(res$alpha, (7 - 4) / 8)
  # the critical quantile is the ratio the newsvendor problem is known for
  expect_equal(res$alpha, (7 - 4) / (1 + 7))
})

test_that("stdize_news_params is vectorized over products", {
  res <- stdize_news_params(ax = c(4, 8), a_minus = c(7, 12), a_plus = c(1, 2))
  expect_equal(res$kappa, c(8, 14))
  expect_equal(res$alpha, c(3 / 8, 4 / 14))
  expect_equal(nrow(res), 2)
})

test_that("stdize_ou_params converts over/under costs", {
  res <- stdize_ou_params(O = 1, U = 3)
  expect_equal(res$kappa, 4)
  expect_equal(res$alpha, 0.75)
})

test_that("stdize_met_params converts cost/loss ratios", {
  res <- stdize_met_params(C = 2, L = 10)
  expect_equal(res$kappa, 10)
  expect_equal(res$alpha, 0.8)
})

test_that("the parameterizations round-trip through kappa and alpha", {
  kappa <- 5
  alpha <- 0.4
  O <- kappa * (1 - alpha)
  U <- kappa * alpha
  res <- stdize_ou_params(O, U)
  expect_equal(res$kappa, kappa)
  expect_equal(res$alpha, alpha)
})
