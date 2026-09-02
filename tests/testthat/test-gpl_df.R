test_that("new_gpl_df recycles scalars and builds one loss per target", {
  gdf <- new_gpl_df(N = 3, alpha = 0.5, target_names = c("a", "b", "c"))
  expect_s3_class(gdf, "gpl_df")
  expect_equal(nrow(gdf), 3)
  expect_equal(gdf$alpha, c(0.5, 0.5, 0.5))
  expect_equal(gdf$target_names, c("a", "b", "c"))
  expect_type(gdf$gpl_loss_fun, "list")
  expect_equal(gdf$gpl_loss_fun[[1]](1, 3), 1)
})

test_that("new_gpl_df accepts vector parameters", {
  gdf <- new_gpl_df(N = 3, alpha = c(0.2, 0.5, 0.8), kappa = c(1, 2, 3))
  expect_equal(gdf$alpha, c(0.2, 0.5, 0.8))
  expect_equal(gdf$kappa, c(1, 2, 3))
  expect_equal(gdf$gpl_loss_fun[[3]](1, 3), 3 * 0.8 * 2)
})

test_that("new_gpl_df infers N from the longest argument", {
  # the original package errored here on an undefined variable
  gdf <- new_gpl_df(alpha = c(0.2, 0.5, 0.8))
  expect_equal(nrow(gdf), 3)
  expect_equal(gdf$alpha, c(0.2, 0.5, 0.8))
})

test_that("new_gpl_df rejects arguments of incompatible length", {
  expect_error(
    new_gpl_df(N = 3, alpha = c(0.2, 0.5)),
    regexp = "must be of length 1 or 3"
  )
})

test_that("new_gpl_df carries a dg column", {
  # the original package dropped dg, so it was silently ignored downstream
  gdf <- new_gpl_df(N = 2, alpha = 0.5)
  expect_true("dg" %in% names(gdf))
  expect_true(all(is.na(gdf$dg)))
})

test_that("dexp_gpl_df builds one derivative per target", {
  gdf <- new_gpl_df(N = 2, alpha = 0.5)
  ds <- dexp_gpl_df(gdf, F = list(pnorm, function(q) pnorm(q, 3)))
  expect_length(ds, 2)
  # each vanishes at its own median
  expect_equal(ds[[1]](0), 0, tolerance = 1e-8)
  expect_equal(ds[[2]](3), 0, tolerance = 1e-8)
})

test_that("dexp_gpl_df validates its inputs", {
  gdf <- new_gpl_df(N = 2, alpha = 0.5)
  expect_error(
    dexp_gpl_df(as.data.frame(gdf), F = list(pnorm, pnorm)),
    regexp = "must be a <gpl_df>"
  )
  expect_error(
    dexp_gpl_df(gdf, F = list(pnorm)),
    regexp = "same number of targets"
  )
})

test_that("meb_gpl_df gives the marginal expected benefit", {
  # Lambda(x) = (kappa / w) * g'(x) * (alpha - F(x)); decreasing, zero at the quantile
  gdf <- new_gpl_df(N = 1, alpha = 0.75, kappa = 2)
  meb <- meb_gpl_df(gdf, F = list(pnorm), w = 4)
  expect_equal(meb[[1]](0), (2 / 4) * (0.75 - 0.5))
  expect_equal(meb[[1]](qnorm(0.75)), 0, tolerance = 1e-8)
  expect_gt(meb[[1]](-1), meb[[1]](1))
})

test_that("meb_gpl_df validates weights", {
  gdf <- new_gpl_df(N = 2, alpha = 0.5)
  expect_error(
    meb_gpl_df(gdf, F = list(pnorm, pnorm), w = "a"),
    regexp = "must be numeric"
  )
  expect_error(
    meb_gpl_df(gdf, F = list(pnorm, pnorm), w = c(1, 2, 3)),
    regexp = "same number of targets"
  )
})

test_that("gpl retrieves the loss data frame of an allocation", {
  a <- allocate(norm_forecasts(), K = 20)
  gdf <- gpl(a)
  expect_s3_class(gdf, "gpl_df")
  expect_equal(nrow(gdf), 3)
  expect_error(
    gpl(tibble::tibble(x = 1)),
    regexp = "must be an <allocated> object"
  )
})
