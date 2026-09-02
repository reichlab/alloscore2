test_that("oracle_allocate_direct allocates the outcomes when affordable", {
  y <- c(3, 5)
  expect_equal(oracle_allocate_direct(y, K = 100, w = 1), y)
  expect_equal(oracle_allocate_direct(y, K = 8, w = 1), y)
})

test_that("oracle_allocate_direct scales proportionally when the budget binds", {
  y <- c(3, 5)
  x <- oracle_allocate_direct(y, K = 4, w = 1)
  expect_equal(sum(x), 4)
  # proportions are preserved
  expect_equal(x[1] / x[2], y[1] / y[2])
  expect_equal(x, y * 4 / 8)
})

test_that("oracle_allocate_direct respects weights", {
  y <- c(3, 5)
  w <- c(2, 1)
  x <- oracle_allocate_direct(y, K = 5.5, w = w)
  expect_equal(sum(w * x), 5.5)
})

test_that("oracle_alloscore_direct scores the oracle's own allocation", {
  y <- c(3, 5)
  gpl_fns <- list(gpl_loss_fun(alpha = 1), gpl_loss_fun(alpha = 1))
  # affordable: the oracle allocates exactly y and incurs no loss
  res <- oracle_alloscore_direct(y, K = 100, w = 1, gpl_fns = gpl_fns)
  expect_equal(res$oracle, y)
  expect_equal(res$components_oracle, c(0, 0))
  # binding: with alpha = 1 the loss is the shortfall
  res2 <- oracle_alloscore_direct(y, K = 4, w = 1, gpl_fns = gpl_fns)
  expect_equal(sum(res2$components_oracle), sum(y) - 4)
})

test_that("oracle_allocate reproduces the direct oracle for alpha = 1", {
  y <- c(4, 9, 11)
  K <- 15
  a <- allocate(norm_forecasts(), K = K)
  o <- oracle_allocate(a, y = y, K = K)
  expect_equal(
    unname(o$x[[1]]),
    oracle_allocate_direct(y, K, w = 1),
    tolerance = 1e-3
  )
})

test_that("oracle_allocate takes weights and losses from an allocated object", {
  fc <- dplyr::mutate(norm_forecasts(), cost = c(1, 2, 4))
  a <- allocate(fc, K = 30, w = "cost", alpha = 0.9)
  o <- oracle_allocate(a, y = c(4, 9, 11), K = 30)
  expect_equal(unname(weights(o)), c(1, 2, 4))
  expect_equal(sum(weights(o) * o$x[[1]]), 30, tolerance = 0.05)
})

test_that("oracle_allocate accepts a bare gpl_df", {
  y <- c(4, 9, 11)
  a <- allocate(norm_forecasts(), K = 15)
  o <- oracle_allocate(
    gpl(a),
    y = y,
    w = 1,
    K = 15,
    target_names = "target_names"
  )
  expect_s3_class(o, "allocated")
  expect_equal(sum(o$x[[1]]), 15, tolerance = 0.05)
})

test_that("the oracle incurs no loss once the budget covers the outcomes", {
  # This, not the allocation vector, is the property the score depends on: with
  # alpha = 1 the loss is (y - x)_+, which is zero as soon as x >= y.
  y <- rlang::set_names(c(4, 9, 11), c("A", "B", "C"))
  for (K in c(30, 50, 100, 500)) {
    s <- alloscore(norm_forecasts(), y = y, K = K)
    expect_equal(s$score_oracle, 0, tolerance = 1e-6)
    o <- oracle_allocate(allocate(norm_forecasts(), K = K), y = y, K = K)
    expect_true(all(o$x[[1]] >= y - 1e-6))
  }
})

test_that("the oracle spends the whole budget even when it has no use for it", {
  # Known limitation carried over from the original package: post-processing
  # forces the budget to be exhausted, so the reported oracle allocation is
  # inflated well past the outcomes once the budget is generous. The loss, and
  # therefore the score, is unaffected.
  y <- rlang::set_names(c(4, 9, 11), c("A", "B", "C"))
  K <- 500
  o <- oracle_allocate(allocate(norm_forecasts(), K = K), y = y, K = K)
  expect_equal(sum(o$x[[1]]), K, tolerance = 1e-6)
  expect_gt(max(o$x[[1]]), 10 * max(y))
})

test_that("oracle_allocate beats the proportional formula for unequal weights", {
  # oracle_allocate_direct scales the outcomes proportionally, which is optimal
  # only when the weights are equal. With unequal weights the cheapest units
  # should be bought first, and oracle_allocate finds that solution.
  y <- rlang::set_names(c(4, 9, 11), c("A", "B", "C"))
  w <- c(1, 2, 4)
  K <- 30
  fc <- dplyr::mutate(norm_forecasts(), cost = w)
  a <- allocate(fc, K = K, w = "cost", alpha = 0.9)
  o <- oracle_allocate(a, y = y, K = K)
  x <- o$x[[1]]
  expect_equal(sum(w * x), K, tolerance = 1e-6)
  # the two cheapest targets are filled, the dearest takes the remainder
  expect_equal(unname(x), c(4, 9, 2), tolerance = 1e-2)
  # and this really is the better allocation
  shortfall <- function(x) sum(pmax(y - x, 0))
  expect_lt(shortfall(x), shortfall(oracle_allocate_direct(y, K, w)))
})
