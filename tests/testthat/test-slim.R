test_that("slim keeps the budgets and allocations of an unscored allocation", {
  a <- allocate(norm_forecasts(), K = c(10, 25))
  s <- slim(a)
  expect_s3_class(s, "slim")
  expect_s3_class(s, "allocated")
  # unscored allocations are unnested by default
  expect_equal(nrow(s), 6)
  expect_true(all(c("K", "target_names", "x", "score_fun") %in% names(s)))
  expect_false("xs" %in% names(s))
  expect_false("lam_seq" %in% names(s))
})

test_that("slim preserves the attributes needed for scoring", {
  a <- allocate(norm_forecasts(), K = c(10, 25))
  s <- slim(a)
  expect_equal(weights(s), weights(a))
  expect_equal(attr(s, "target_col_name"), "target_names")
  expect_s3_class(attr(s, "gpl_df"), "gpl_df")
})

test_that("slim leaves a scored allocation nested and drops the scoring function", {
  s <- slim(alloscore(norm_forecasts(), y = c(4, 9, 11), K = c(10, 25)))
  expect_equal(nrow(s), 2)
  expect_true(all(
    c("K", "xdf", "score_raw", "score_oracle", "score") %in% names(s)
  ))
  expect_false("score_fun" %in% names(s$xdf[[1]]))
})

test_that("xdf_action controls nesting", {
  a <- allocate(norm_forecasts(), K = c(10, 25))
  expect_equal(nrow(slim(a, xdf_action = "nest")), 2)
  expect_equal(nrow(slim(a, xdf_action = "unnest")), 6)
  scored <- alloscore(norm_forecasts(), y = c(4, 9, 11), K = c(10, 25))
  expect_equal(nrow(slim(scored, xdf_action = "unnest")), 6)
})

test_that("slim keeps requested id columns", {
  a <- allocate(norm_forecasts(), K = c(10, 25))
  a$model <- "m1"
  s <- slim(a, id_cols = "model")
  expect_true("model" %in% names(s))
  expect_equal(unique(s$model), "m1")
})

test_that("rm_score_fun arguments control dropping the scoring closure", {
  a <- allocate(norm_forecasts(), K = 10)
  expect_true("score_fun" %in% names(slim(a, xdf_action = "unnest")))
  expect_false(
    "score_fun" %in%
      names(slim(a, xdf_action = "unnest", rm_score_fun_if_not_scored = TRUE))
  )
  scored <- alloscore(norm_forecasts(), y = c(4, 9, 11), K = 10)
  expect_true(
    "score_fun" %in%
      names(slim(scored, rm_score_fun_if_scored = FALSE)$xdf[[1]])
  )
})

test_that("weights.allocated retrieves the weights", {
  fc <- dplyr::mutate(norm_forecasts(), cost = c(1, 2, 4))
  a <- allocate(fc, K = 30, w = "cost", alpha = 0.9)
  expect_equal(unname(weights(a)), c(1, 2, 4))
  expect_equal(names(weights(a)), c("A", "B", "C"))
})
