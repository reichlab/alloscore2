test_that("pdqr_factory fixes parameters for a named distribution", {
  F <- pdqr_factory(mean = 5, sd = 2, dist = "norm", type = "p")
  expect_equal(F(5), 0.5)
  expect_equal(F(7), pnorm(7, 5, 2))
  Q <- pdqr_factory(mean = 5, sd = 2, dist = "norm", type = "q")
  expect_equal(Q(0.5), 5)
  d <- pdqr_factory(mean = 5, sd = 2, dist = "norm", type = "d")
  expect_equal(d(5), dnorm(5, 5, 2))
})

test_that("pdqr_factory ignores parameters the distribution does not take", {
  # whole rows of a forecast data frame are passed in, so extras are expected
  F <- pdqr_factory(
    mean = 5,
    sd = 2,
    irrelevant = "ignored",
    dist = "norm",
    type = "p"
  )
  expect_equal(F(5), 0.5)
})

test_that("pdqr_factory rescales a bounded support via trans and trans_inv", {
  x_min <- 100
  x_max <- 300
  F <- pdqr_factory(
    shape1 = 2,
    shape2 = 1,
    x_min = x_min,
    x_max = x_max,
    dist = "beta",
    type = "p",
    trans = function(x, x_min, x_max) (x - x_min) / (x_max - x_min),
    trans_inv = function(q, x_min, x_max) x_min + (x_max - x_min) * q
  )
  Q <- pdqr_factory(
    shape1 = 2,
    shape2 = 1,
    x_min = x_min,
    x_max = x_max,
    dist = "beta",
    type = "q",
    trans = function(x, x_min, x_max) (x - x_min) / (x_max - x_min),
    trans_inv = function(q, x_min, x_max) x_min + (x_max - x_min) * q
  )
  expect_equal(F(x_min), 0)
  expect_equal(F(x_max), 1)
  expect_equal(F(200), pbeta(0.5, 2, 1))
  # F and Q invert one another on the rescaled support
  expect_equal(F(Q(0.3)), 0.3, tolerance = 1e-8)
  expect_gte(Q(0.001), x_min)
  expect_lte(Q(0.999), x_max)
})

test_that("pdqr_factory interpolates a distribution through quantiles", {
  ps <- c(0.1, 0.25, 0.5, 0.75, 0.9)
  qs <- c(10, 20, 30, 45, 60)
  F <- pdqr_factory(ps = ps, qs = qs, dist = "distfromq", type = "p")
  Q <- pdqr_factory(ps = ps, qs = qs, dist = "distfromq", type = "q")
  # the supplied quantiles are reproduced
  expect_equal(Q(ps), qs, tolerance = 1e-6)
  expect_equal(F(qs), ps, tolerance = 1e-6)
  # and the cdf is non-decreasing
  grid <- seq(5, 70, length.out = 50)
  expect_true(all(diff(F(grid)) >= -1e-9))
})

test_that("add_pdqr_funs adds the requested list columns", {
  fc <- add_pdqr_funs(
    tibble::tibble(
      target_names = c("a", "b"),
      dist = "norm",
      mean = c(5, 8),
      sd = c(1, 2)
    ),
    types = c("p", "d", "q")
  )
  expect_true(all(c("F", "f", "Q") %in% names(fc)))
  expect_false("r" %in% names(fc))
  expect_type(fc$F, "list")
  expect_equal(fc$F[[1]](5), 0.5)
  expect_equal(fc$F[[2]](8), 0.5)
  expect_equal(fc$Q[[2]](0.5), 8)
  expect_s3_class(fc, "tbl_df")
})

test_that("add_pdqr_funs takes the distribution from an argument or a column", {
  base <- tibble::tibble(target_names = c("a", "b"), mean = c(5, 8), sd = 1)
  fc <- add_pdqr_funs(base, dist = "norm", types = "p")
  expect_equal(fc$F[[1]](5), 0.5)
  expect_equal(fc$dist, c("norm", "norm"))
  expect_error(
    add_pdqr_funs(base, dist = NULL, types = "p"),
    regexp = "Distributions must be specified"
  )
})

test_that("add_pdqr_funs allows per-target distributions", {
  fc <- add_pdqr_funs(
    tibble::tibble(
      target_names = c("a", "b"),
      dist = c("norm", "lnorm"),
      mean = c(5, NA),
      sd = c(1, NA),
      meanlog = c(NA, 1),
      sdlog = c(NA, 0.5)
    ),
    types = "q"
  )
  expect_equal(fc$Q[[1]](0.5), 5)
  expect_equal(fc$Q[[2]](0.5), qlnorm(0.5, 1, 0.5))
})
