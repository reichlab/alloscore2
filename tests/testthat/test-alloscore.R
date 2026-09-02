test_that("alloscore returns scores for each budget", {
  s <- alloscore(norm_forecasts(), y = c(4, 9, 11), K = c(10, 25, 50))
  expect_s3_class(s, "scored")
  expect_s3_class(s, "allocated")
  expect_equal(nrow(s), 3)
  expect_true(all(
    c("K", "score", "score_raw", "score_oracle", "ytot", "xdf") %in% names(s)
  ))
})

test_that("the score is the forecaster's loss less the oracle's", {
  s <- alloscore(norm_forecasts(), y = c(4, 9, 11), K = c(10, 25))
  expect_equal(s$score, s$score_raw - s$score_oracle)
})

test_that("score_raw is the sum of the per-target components", {
  s <- alloscore(norm_forecasts(), y = c(4, 9, 11), K = c(10, 25))
  for (i in seq_len(nrow(s))) {
    expect_equal(s$score_raw[i], sum(s$xdf[[i]]$components_raw))
    expect_equal(s$score_oracle[i], sum(s$xdf[[i]]$components_oracle))
    expect_equal(
      s$xdf[[i]]$components,
      s$xdf[[i]]$components_raw - s$xdf[[i]]$components_oracle
    )
  }
})

test_that("ytot is the total weighted outcome", {
  y <- c(4, 9, 11)
  fc <- dplyr::mutate(norm_forecasts(), cost = c(1, 2, 4))
  s <- alloscore(fc, y = y, K = 30, w = "cost", alpha = 0.9)
  expect_equal(s$ytot, sum(c(1, 2, 4) * y))
})

test_that("a perfect forecast scores zero", {
  # point masses at the outcomes make the forecaster the oracle
  y <- c(4, 9, 11)
  perfect <- tibble::tibble(
    target_names = c("A", "B", "C"),
    F = purrr::map(y, function(yi) function(x) 1 * (x >= yi)),
    Q = purrr::map(y, function(yi) function(p) yi)
  )
  s <- alloscore(perfect, y = y, K = 15)
  expect_equal(s$score, 0, tolerance = 1e-6)
})

test_that("components_raw is the gpl loss at the allocation", {
  y <- c(4, 9, 11)
  s <- alloscore(norm_forecasts(), y = y, K = 20)
  xdf <- s$xdf[[1]]
  expect_equal(xdf$y, y, ignore_attr = TRUE)
  expect_equal(xdf$components_raw, pmax(y - xdf$x, 0), ignore_attr = TRUE)
})

test_that("against_oracle = FALSE omits the oracle columns", {
  s <- alloscore(
    norm_forecasts(),
    y = c(4, 9, 11),
    K = c(10, 25),
    against_oracle = FALSE
  )
  expect_true("score_raw" %in% names(s))
  expect_false("score" %in% names(s))
  expect_false("score_oracle" %in% names(s))
  expect_false("components_oracle" %in% names(s$xdf[[1]]))
})

test_that("allocating then scoring matches doing both at once", {
  y <- c(4, 9, 11)
  Ks <- c(10, 25)
  direct <- alloscore(norm_forecasts(), y = y, K = Ks)
  piped <- alloscore(
    allocate(norm_forecasts(), K = Ks),
    y = rlang::set_names(y, c("A", "B", "C"))
  )
  expect_equal(piped$score, direct$score)
  expect_equal(piped$score_raw, direct$score_raw)
})

test_that("passing F and Q directly matches passing a data frame", {
  y <- c(4, 9, 11)
  fc <- norm_forecasts()
  from_df <- alloscore(fc, y = y, K = c(10, 30))
  from_args <- alloscore(F = fc$F, Q = fc$Q, y = y, K = c(10, 30))
  expect_equal(from_args$score, from_df$score)
})

test_that("alloscore errors when y does not match the targets", {
  expect_error(
    alloscore(allocate(norm_forecasts(), K = 20), y = c(1, 2)),
    regexp = "`y` has length 2 but there are 3 targets"
  )
})

test_that("scoring a slim allocation over many outcomes matches the full path", {
  Ks <- c(10, 25)
  y <- rlang::set_names(c(4, 9, 11), c("A", "B", "C"))
  full <- alloscore(allocate(norm_forecasts(), K = Ks), y = y)
  slim_scored <- alloscore(slim(allocate(norm_forecasts(), K = Ks)), list(y))
  expect_equal(nrow(slim_scored), 1)
  expect_equal(slim_scored$samp, "1")
  expect_equal(
    slim_scored$scores[[1]]$score_raw,
    full$score_raw,
    tolerance = 1e-8
  )
  # the slim path uses the closed-form oracle, which agrees for alpha = 1
  expect_equal(
    slim_scored$scores[[1]]$score_oracle,
    full$score_oracle,
    tolerance = 1e-3
  )
})

test_that("alloscore.slim handles several outcome vectors", {
  ys <- list(
    rlang::set_names(c(4, 9, 11), c("A", "B", "C")),
    rlang::set_names(c(6, 7, 14), c("A", "B", "C"))
  )
  s <- alloscore(slim(allocate(norm_forecasts(), K = c(10, 25))), ys)
  expect_equal(nrow(s), 2)
  expect_equal(s$samp, c("1", "2"))
  expect_equal(nrow(s$scores[[1]]), 2)
  expect_true(all(
    c("K", "ytot", "score_raw", "score_oracle", "score") %in%
      names(s$scores[[1]])
  ))
})

test_that("alloscore.slim honors against_oracle", {
  # the original package accepted this argument and ignored it
  ys <- list(rlang::set_names(c(4, 9, 11), c("A", "B", "C")))
  s <- alloscore(
    slim(allocate(norm_forecasts(), K = 10)),
    ys,
    against_oracle = FALSE
  )
  expect_true("score_raw" %in% names(s$scores[[1]]))
  expect_false("score" %in% names(s$scores[[1]]))
  expect_false("components_oracle" %in% names(s$xdf[[1]]))
})

test_that("alloscore.slim requires consistently named outcomes", {
  a <- slim(allocate(norm_forecasts(), K = 10))
  expect_error(
    alloscore(a, list(c(1, 2, 3))),
    regexp = "consistently named by their targets"
  )
  expect_error(
    alloscore(
      a,
      list(
        rlang::set_names(c(1, 2, 3), c("A", "B", "C")),
        rlang::set_names(c(1, 2, 3), c("A", "B", "X"))
      )
    ),
    regexp = "consistently named by their targets"
  )
})
