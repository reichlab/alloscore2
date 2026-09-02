test_that("get_function evaluates increment functions from strings", {
  expect_equal(get_function("x")(3), 3)
  expect_equal(get_function("log(x)")(exp(2)), 2)
  expect_equal(get_function("exp(x)")(1), exp(1))
  # a general expression goes through parse()
  expect_equal(get_function("log(1+x)")(1), log(2))
  expect_equal(get_function("x^2")(3), 9)
})

test_that("get_derivative differentiates increment functions from strings", {
  expect_equal(get_derivative("x")(5), 1)
  expect_equal(get_derivative("log(x)")(4), 1 / 4)
  expect_equal(get_derivative("exp(x)")(1), exp(1))
  expect_equal(get_derivative("log(1+x)")(1), 0.5)
  expect_equal(get_derivative("x^2")(3), 6)
})

test_that("get_function and get_derivative require the variable x", {
  expect_error(
    get_function("log(z)"),
    regexp = "must be used in the function string"
  )
  expect_error(
    get_derivative("2*y"),
    regexp = "must be used in the function string"
  )
})

test_that("resolve_dg prefers a supplied dg and falls back to g", {
  expect_equal(resolve_dg("x", function(x) 7)(1), 7)
  expect_equal(resolve_dg("log(x)", NULL)(4), 1 / 4)
  # NA is treated as absent, as allocate() passes it
  expect_equal(resolve_dg("log(x)", NA)(4), 1 / 4)
  expect_equal(resolve_dg("x", "2*x")(3), 6)
  expect_error(
    resolve_dg(function(x) x, NULL),
    regexp = "Cannot derive `dg` from a <function> `g`"
  )
})

test_that("is_empty_arg identifies only NULL and scalar NA", {
  expect_true(is_empty_arg(NULL))
  expect_true(is_empty_arg(NA))
  expect_false(is_empty_arg(1))
  expect_false(is_empty_arg(sum))
  expect_false(is_empty_arg(list(sum)))
  expect_false(is_empty_arg(character(0)))
  expect_false(is_empty_arg(c(NA, NA)))
})

test_that("resolve_df_args overrides defaulted arguments from like-named columns", {
  df <- data.frame(kappa = c(1, 2, 3), alpha = c(.5, .6, .7))
  res <- resolve_df_args(
    df,
    vals = list(kappa = 1, alpha = 1),
    has_default = c("kappa", "alpha")
  )
  expect_equal(res$kappa, c(1, 2, 3))
  expect_equal(res$alpha, c(.5, .6, .7))
  expect_setequal(attr(res, "args_from_df"), c("kappa", "alpha"))
})

test_that("resolve_df_args fills empty arguments from like-named columns", {
  df <- data.frame(w = c(2, 3))
  res <- resolve_df_args(
    df,
    vals = list(w = NULL, other = NA),
    has_default = character()
  )
  expect_equal(res$w, c(2, 3))
  # no `other` column, so it stays empty
  expect_true(is.na(res$other))
  expect_equal(attr(res, "args_from_df"), "w")
})

test_that("resolve_df_args treats a length-1 string as a column name", {
  df <- data.frame(cost = c(4, 5, 6), Product = c("a", "b", "c"))
  res <- resolve_df_args(
    df,
    vals = list(w = "cost", target_names = "Product"),
    has_default = "w"
  )
  expect_equal(res$w, c(4, 5, 6))
  expect_equal(res$target_names, c("a", "b", "c"))
})

test_that("resolve_df_args leaves values alone when no column matches", {
  df <- data.frame(z = 1:3)
  res <- resolve_df_args(
    df,
    vals = list(w = 2, g = "x"),
    has_default = c("w", "g")
  )
  expect_equal(res$w, 2)
  expect_equal(res$g, "x")
  expect_equal(attr(res, "args_from_df"), character(0))
})

test_that("unirootL finds the root of a decreasing function", {
  expect_equal(unirootL(function(x) 1 - x, 0, 5, 1e-3), 1, tolerance = 1e-6)
})

test_that("unirootL steps left of a plateau to stay non-negative", {
  # a step function has a flat stretch at zero; we want its left-hand end
  f <- function(x) ifelse(x < 2, 1, -1)
  root <- unirootL(f, 0, 5, point_mass_window = 0.1)
  expect_true(f(root) >= 0)
  expect_lt(root, 2)
})

test_that("unirootL clamps at the lower bound and errors on a narrow window", {
  expect_equal(unirootL(function(x) -1 - x, -1, 5, point_mass_window = 10), -1)
  expect_error(
    unirootL(
      function(x) ifelse(x < 1e-9, 1, -1),
      0,
      5,
      point_mass_window = 1e-12
    ),
    regexp = "Point mass window too narrow"
  )
})
