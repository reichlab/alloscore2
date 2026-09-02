test_that("allocate returns one row per budget with the documented columns", {
  a <- allocate(norm_forecasts(), K = c(10, 20, 50))
  expect_s3_class(a, "allocated")
  expect_equal(nrow(a), 3)
  expect_equal(a$K, c(10, 20, 50))
  expect_true(all(
    c(
      "K",
      "x",
      "xs",
      "qs_OK",
      "lam",
      "lamL",
      "lamU",
      "post_processed",
      "xdf"
    ) %in%
      names(a)
  ))
  expect_equal(attr(a, "target_col_name"), "target_names")
  expect_s3_class(attr(a, "gpl_df"), "gpl_df")
  expect_equal(names(attr(a, "w")), c("A", "B", "C"))
})

test_that("allocate exhausts the budget to within eps_K", {
  Ks <- c(10, 20, 50)
  a <- allocate(norm_forecasts(), K = Ks, alpha = 0.9)
  w <- weights(a)
  spent <- vapply(a$x, function(x) sum(w * x), numeric(1))
  # only budgets that actually bind should be spent
  binding <- !a$qs_OK
  expect_true(any(binding))
  expect_equal(spent[binding], Ks[binding], tolerance = 0.01)
})

test_that("allocations are non-negative and named by target", {
  a <- allocate(norm_forecasts(), K = c(5, 30))
  for (x in a$x) {
    expect_true(all(x >= 0))
    expect_equal(names(x), c("A", "B", "C"))
  }
})

test_that("an unbinding budget gives the alpha-quantile of each forecast", {
  # with a budget far above the total need, each allocation is its own quantile
  alpha <- 0.8
  fc <- norm_forecasts()
  a <- allocate(fc, K = 1e6, alpha = alpha)
  expect_true(a$qs_OK)
  expect_equal(
    unname(a$x[[1]]),
    vapply(fc$Q, function(Q) Q(alpha), numeric(1)),
    tolerance = 1e-8
  )
})

test_that("allocating over a vector of budgets matches looping over them", {
  # solving all K at once is an optimization, not a change of answer
  Ks <- c(8, 15, 32)
  together <- allocate(norm_forecasts(), K = Ks, alpha = 0.9)
  separate <- lapply(Ks, function(K) {
    allocate(norm_forecasts(), K = K, alpha = 0.9)
  })
  for (i in seq_along(Ks)) {
    expect_equal(together$x[[i]], separate[[i]]$x[[1]], tolerance = 1e-8)
    expect_equal(together$lam[i], separate[[i]]$lam[1], tolerance = 1e-8)
  }
})

test_that("more budget never means less allocation in total", {
  a <- allocate(norm_forecasts(), K = c(5, 10, 20, 40), alpha = 0.95)
  w <- weights(a)
  spent <- vapply(a$x, function(x) sum(w * x), numeric(1))
  expect_true(all(diff(spent) >= -1e-6))
})

test_that("weights can be given as a column name and are used in the constraint", {
  fc <- dplyr::mutate(norm_forecasts(), cost = c(1, 2, 4))
  a <- allocate(fc, K = 20, w = "cost", alpha = 0.9)
  expect_equal(unname(weights(a)), c(1, 2, 4))
  expect_equal(sum(weights(a) * a$x[[1]]), 20, tolerance = 0.01)
})

test_that("target names can come from a column", {
  fc <- dplyr::rename(norm_forecasts(), site = "target_names")
  a <- allocate(fc, K = 20, target_names = "site")
  expect_equal(attr(a, "target_col_name"), "site")
  expect_true("site" %in% names(a$xdf[[1]]))
  expect_equal(a$xdf[[1]]$site, c("A", "B", "C"))
})

test_that("target names default to indices", {
  fc <- dplyr::select(norm_forecasts(), -"target_names")
  a <- allocate(fc, K = 20)
  expect_equal(a$xdf[[1]]$target_names, c("1", "2", "3"))
})

test_that("allocate accepts F and Q as individual arguments", {
  fc <- norm_forecasts()
  from_df <- allocate(fc, K = c(10, 25), alpha = 0.9)
  from_args <- allocate(F = fc$F, Q = fc$Q, K = c(10, 25), alpha = 0.9)
  expect_equal(
    unname(from_args$x[[1]]),
    unname(from_df$x[[1]]),
    tolerance = 1e-8
  )
  expect_equal(
    unname(from_args$x[[2]]),
    unname(from_df$x[[2]]),
    tolerance = 1e-8
  )
})

test_that("allocate errors without predictive cdfs", {
  expect_error(
    allocate(K = 10, Q = list(qnorm)),
    regexp = "Predictive cdfs `F` must be supplied"
  )
})

test_that("allocate errors on weights of the wrong length", {
  expect_error(
    allocate(norm_forecasts(), K = 10, w = c(1, 2)),
    regexp = "`w` must have length 1 or 3"
  )
})

test_that("allocate rejects increment functions with an unbounded derivative at zero", {
  # the original package messaged and returned its initial iterate unchanged
  expect_error(
    allocate(norm_forecasts(), K = 20, g = "log(x)"),
    regexp = "not finite, so lambda cannot be bracketed"
  )
})

test_that("a shifted log increment function works", {
  a <- allocate(norm_forecasts(), K = c(15, 30), g = "log(1+x)")
  expect_equal(nrow(a), 2)
  expect_true(all(vapply(a$x, function(x) all(is.finite(x)), logical(1))))
})

test_that("allocate gives everything to nobody when there is no marginal benefit", {
  # all of the predictive mass lies below zero, so no allocation can reduce loss
  expect_message(
    a <- allocate(below_zero_forecasts(), K = c(5, 10)),
    regexp = "All targets receiving zero allocation"
  )
  expect_equal(unname(a$x[[1]]), c(0, 0, 0))
  expect_equal(unname(a$x[[2]]), c(0, 0, 0))
  # The frame must still be well formed. The original package returned one with
  # no xdf column, no `allocated` class and no attributes, so nothing
  # downstream could consume it.
  expect_s3_class(a, "allocated")
  expect_true("xdf" %in% names(a))
  expect_equal(nrow(a$xdf[[1]]), 3)
  expect_equal(a$xdf[[1]]$target_names, c("A", "B", "C"))
  expect_false(any(a$post_processed))
  expect_equal(names(weights(a)), c("A", "B", "C"))
  expect_false(any(c("converged", "lam_prev") %in% names(a)))
  # and it must still be scorable (the oracle's own allocation is zero too,
  # which is why scoring it emits the same message)
  expect_no_error(suppressMessages(alloscore(a, y = c(-9, -13, -14))))
})

test_that("a quantile level below F(0) yields a negative allocation", {
  # Known limitation, carried over unchanged from the original package: when
  # alpha is small enough that the alpha-quantile is negative, that quantile is
  # reported as the unconstrained solution without being clamped at zero.
  a <- allocate(norm_forecasts(), K = c(5, 10), alpha = 1e-12)
  expect_true(all(a$qs_OK))
  expect_true(all(a$x[[1]] < 0))
})

test_that("post_process interpolates an over-budget allocation onto the budget", {
  # marginal benefit declining linearly, so the bracketing search has a root
  Lambda <- list(function(x) 1 - x / 10, function(x) 1 - x / 10)
  x <- post_process(
    x = c(8, 8),
    K = 12,
    lam = 0.5,
    w = c(1, 1),
    Lambda = Lambda,
    eps_lam = 1e-4,
    point_mass_window = 1e-3
  )
  expect_equal(sum(x), 12, tolerance = 1e-6)
  expect_true(all(x >= 0))
  expect_true(all(x <= 8))
})

test_that("post_process leaves a target alone when it cannot be reduced", {
  # A target whose marginal benefit exceeds the shadow price across the whole
  # bracket has no root to find, and keeps its allocation as its own lower end.
  Lambda <- list(function(x) 10, function(x) 1 - x / 10)
  x <- post_process(
    x = c(4, 8),
    K = 9,
    lam = 0.5,
    w = c(1, 1),
    Lambda = Lambda,
    eps_lam = 1e-4,
    point_mass_window = 1e-3
  )
  expect_equal(sum(x), 9, tolerance = 1e-6)
  expect_equal(x[1], 4)
})

test_that("allocations against point masses need post-processing", {
  # the oracle's degenerate distributions always produce plateaus
  fc <- norm_forecasts()
  a <- allocate(fc, K = 20)
  o <- oracle_allocate(a, y = c(4, 9, 11), K = 20)
  expect_true(any(o$post_processed))
  expect_equal(sum(weights(a) * o$x[[1]]), 20, tolerance = 0.01)
})

test_that("the iteration history has one column per lambda step", {
  a <- allocate(norm_forecasts(), K = 20, alpha = 0.9)
  xs <- a$xs[[1]]
  expect_true("target_names" %in% names(xs))
  iter_cols <- setdiff(names(xs), "target_names")
  expect_true(length(iter_cols) >= 2)
  expect_equal(iter_cols, as.character(seq_along(iter_cols) - 1))
  # the recorded lambda sequence matches the number of steps taken
  expect_length(a$lam_seq[[1]], length(iter_cols))
})

test_that("xdf holds a scoring function per target", {
  a <- allocate(norm_forecasts(), K = 20)
  xdf <- a$xdf[[1]]
  expect_equal(names(xdf), c("target_names", "x", "score_fun"))
  # the scoring function is the gpl loss at that target's allocation
  expect_equal(
    xdf$score_fun[[1]](10),
    gpl_loss_fun(alpha = 1)(xdf$x[1], 10)
  )
})
