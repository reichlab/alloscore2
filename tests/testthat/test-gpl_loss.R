test_that("under_loss and over_loss penalize only one direction", {
  ul <- under_loss()
  ol <- over_loss()
  expect_equal(ul(x = 1, y = 3), 2)
  expect_equal(ul(x = 3, y = 1), 0)
  expect_equal(ol(x = 3, y = 1), 2)
  expect_equal(ol(x = 1, y = 3), 0)
})

test_that("under_loss and over_loss accept a string increment function", {
  expect_equal(under_loss("log(x)")(x = 1, y = exp(2)), 2)
  expect_equal(over_loss("log(x)")(x = exp(2), y = 1), 2)
  # a supplied function is used as given
  expect_equal(under_loss(function(u) u^2)(x = 1, y = 3), 8)
})

test_that("gpl_loss_fun is the pinball loss when g is the identity", {
  for (alpha in c(0.1, 0.5, 0.9)) {
    L <- gpl_loss_fun(alpha = alpha)
    # pinball loss at level alpha
    expect_equal(L(x = 1, y = 3), alpha * 2)
    expect_equal(L(x = 3, y = 1), (1 - alpha) * 2)
    # zero at a perfect allocation
    expect_equal(L(x = 2, y = 2), 0)
  }
})

test_that("gpl_loss_fun scales by kappa and adds an offset", {
  expect_equal(gpl_loss_fun(alpha = 0.5, kappa = 4)(x = 1, y = 3), 4)
  expect_equal(gpl_loss_fun(alpha = 0.5, offset = 7)(x = 2, y = 2), 7)
  L <- gpl_loss_fun(alpha = 0.5, offset = function(y) y^2)
  expect_equal(L(x = 2, y = 3), 0.5 + 9)
})

test_that("the O/U parameterization matches the kappa/alpha one", {
  # O = kappa * (1 - alpha), U = kappa * alpha
  O <- 1
  U <- 3
  kappa <- O + U
  alpha <- U / (O + U)
  xs <- c(0.5, 1, 2, 5)
  expect_equal(
    gpl_loss_fun(O = O, U = U)(xs, 2),
    gpl_loss_fun(kappa = kappa, alpha = alpha)(xs, 2)
  )
  expect_equal(
    exp_gpl_loss_fun(F = pnorm, O = O, U = U)(xs),
    exp_gpl_loss_fun(F = pnorm, kappa = kappa, alpha = alpha)(xs)
  )
  expect_equal(
    dexp_gpl_loss(F = pnorm, O = O, U = U)(xs),
    dexp_gpl_loss(F = pnorm, kappa = kappa, alpha = alpha)(xs)
  )
  expect_equal(unlist(stdize_ou_params(O, U)), c(kappa = kappa, alpha = alpha))
})

test_that("exactly one of alpha and U must be supplied", {
  expect_error(
    gpl_loss_fun(),
    regexp = "Either `U` or `alpha` must be specified"
  )
  expect_error(
    gpl_loss_fun(alpha = 0.5, U = 1, O = 1),
    regexp = "Either `U` or `alpha` must be specified"
  )
  expect_error(
    gpl_loss_fun(U = 1),
    regexp = "`O` must be specified alongside `U`"
  )
  expect_error(gpl_loss_fun(O = 0, U = 0), regexp = "must not sum to zero")
})

test_that("expected losses agree with closed forms for the normal", {
  # E(Y - x)_+ = (mu - x) * (1 - F(x)) + sd^2 * f(x) for Y ~ N(mu, sd)
  mu <- 2
  sd <- 3
  F <- function(q) pnorm(q, mu, sd)
  xs <- c(-1, 0, 2, 5)
  expected_under <- (mu - xs) *
    (1 - pnorm(xs, mu, sd)) +
    sd^2 * dnorm(xs, mu, sd)
  expect_equal(exp_under_loss(F = F)(xs), expected_under, tolerance = 1e-5)

  # E(x - Y)_+ = (x - mu) * F(x) + sd^2 * f(x)
  expected_over <- (xs - mu) * pnorm(xs, mu, sd) + sd^2 * dnorm(xs, mu, sd)
  expect_equal(exp_over_loss(F = F)(xs), expected_over, tolerance = 1e-5)
})

test_that("dexp_* are the derivatives of exp_*", {
  F <- pnorm
  xs <- c(-1, 0, 1, 2)
  eps <- 1e-5
  fd_under <- (exp_under_loss(F = F)(xs + eps) -
    exp_under_loss(F = F)(xs - eps)) /
    (2 * eps)
  expect_equal(dexp_under_loss(F = F)(xs), fd_under, tolerance = 1e-4)
  fd_over <- (exp_over_loss(F = F)(xs + eps) - exp_over_loss(F = F)(xs - eps)) /
    (2 * eps)
  expect_equal(dexp_over_loss(F = F)(xs), fd_over, tolerance = 1e-4)
})

test_that("dexp_gpl_loss vanishes at the alpha-quantile of the forecast", {
  # the unconstrained optimum is the alpha-quantile, where kappa*g'(x)*(F(x)-alpha) = 0
  for (alpha in c(0.25, 0.5, 0.75)) {
    d <- dexp_gpl_loss(F = pnorm, alpha = alpha)
    expect_equal(d(qnorm(alpha)), 0, tolerance = 1e-8)
  }
})

test_that("dexp_gpl_loss handles alpha = 1 with an unbounded derivative", {
  # the over-prediction term drops out, avoiding 0 * Inf
  d <- dexp_gpl_loss(g = "log(x)", F = plnorm, alpha = 1, kappa = 2)
  expect_true(all(is.finite(d(c(0.5, 1, 2)))))
})

test_that("dexp_gpl_loss requires a cdf", {
  expect_error(dexp_gpl_loss(alpha = 0.5), regexp = "`F` is missing")
})

test_that("a supplied dg is honored rather than derived from g", {
  # the original package silently ignored dg
  xs <- c(0.5, 1, 2)
  expect_equal(
    dexp_under_loss(g = "x", dg = function(x) 2, F = pnorm)(xs),
    2 * (pnorm(xs) - 1)
  )
  expect_equal(
    dexp_over_loss(g = "x", dg = function(x) 2, F = pnorm)(xs),
    2 * pnorm(xs)
  )
})

test_that("exp_gpl_loss_fun honors a constant offset and rejects a function", {
  # the original package accepted offset and dropped it
  base <- exp_gpl_loss_fun(F = pnorm, alpha = 0.6)
  shifted <- exp_gpl_loss_fun(F = pnorm, alpha = 0.6, offset = 10)
  expect_equal(shifted(c(0, 1)) - base(c(0, 1)), c(10, 10))
  expect_error(
    exp_gpl_loss_fun(F = pnorm, alpha = 0.6, offset = function(y) y),
    regexp = "function-valued `offset` is not supported"
  )
})
