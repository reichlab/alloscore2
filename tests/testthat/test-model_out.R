test_that("as_alloscore_df nests one row per allocation unit", {
  adf <- as_alloscore_df(
    mini_model_out(),
    mini_oracle_out(),
    target_cols = "location"
  )
  # 2 models x 1 reference_date x 1 horizon
  expect_equal(nrow(adf), 2)
  expect_true("forecasts" %in% names(adf))
  expect_setequal(
    attr(adf, "allocation_unit"),
    c("model_id", "reference_date", "target", "horizon", "target_end_date")
  )
  expect_equal(attr(adf, "target_cols"), "location")
})

test_that("as_alloscore_df builds a cdf and quantile function per target", {
  adf <- as_alloscore_df(
    mini_model_out(),
    mini_oracle_out(),
    target_cols = "location"
  )
  fc <- adf$forecasts[[1]]
  expect_equal(nrow(fc), 2)
  expect_true(all(
    c("location", "target_names", "y", "ps", "qs", "F", "Q") %in% names(fc)
  ))
  expect_type(fc$F, "list")
  # the predictive quantiles are reproduced by the interpolated functions
  expect_equal(fc$Q[[1]](fc$ps[[1]]), fc$qs[[1]], tolerance = 1e-6)
  expect_equal(fc$F[[1]](fc$qs[[1]]), fc$ps[[1]], tolerance = 1e-6)
})

test_that("as_alloscore_df sorts quantile levels ascending", {
  shuffled <- mini_model_out()[sample(nrow(mini_model_out())), ]
  adf <- as_alloscore_df(shuffled, mini_oracle_out(), target_cols = "location")
  for (fc in adf$forecasts) {
    for (ps in fc$ps) {
      expect_equal(ps, sort(ps))
    }
    for (qs in fc$qs) {
      expect_equal(qs, sort(qs))
    }
  }
})

test_that("as_alloscore_df attaches the observed outcomes", {
  adf <- as_alloscore_df(
    mini_model_out(),
    mini_oracle_out(),
    target_cols = "location"
  )
  for (fc in adf$forecasts) {
    expect_equal(fc$y[fc$location == "a"], 45)
    expect_equal(fc$y[fc$location == "b"], 95)
  }
})

test_that("as_alloscore_df works without oracle output", {
  adf <- as_alloscore_df(mini_model_out(), target_cols = "location")
  expect_false("y" %in% names(adf$forecasts[[1]]))
  expect_true("F" %in% names(adf$forecasts[[1]]))
})

test_that("as_alloscore_df builds a compound key for several target columns", {
  mot <- dplyr::bind_rows(
    mini_model_out(),
    dplyr::mutate(mini_model_out(), target = "inc death")
  )
  oo <- dplyr::bind_rows(
    mini_oracle_out(),
    dplyr::mutate(mini_oracle_out(), target = "inc death")
  )
  adf <- as_alloscore_df(mot, oo, target_cols = c("location", "target"))
  # location and target now vary within an allocation unit
  expect_equal(nrow(adf), 2)
  fc <- adf$forecasts[[1]]
  expect_equal(nrow(fc), 4)
  expect_true(all(grepl("\\|", fc$target_names)))
})

test_that("as_alloscore_df rejects duplicated forecasts", {
  mot <- dplyr::bind_rows(mini_model_out(), mini_model_out())
  expect_error(
    as_alloscore_df(mot, mini_oracle_out(), target_cols = "location"),
    regexp = "duplicated forecast"
  )
})

test_that("as_alloscore_df errors when the oracle output does not cover the forecasts", {
  oo <- dplyr::filter(mini_oracle_out(), .data$location == "a")
  expect_error(
    as_alloscore_df(mini_model_out(), oo, target_cols = "location"),
    regexp = "no matching value in"
  )
})

test_that("as_alloscore_df rejects non-numeric quantile levels", {
  mot <- dplyr::mutate(mini_model_out(), output_type_id = "low")
  expect_error(
    as_alloscore_df(mot, mini_oracle_out(), target_cols = "location"),
    regexp = "not numeric quantile levels"
  )
})

test_that("allocate_model_out allocates once per unit and budget", {
  res <- allocate_model_out(
    mini_model_out(),
    K = c(50, 200),
    target_cols = "location"
  )
  expect_equal(nrow(res), 4)
  expect_true(all(c("model_id", "K", "x", "xdf") %in% names(res)))
  expect_setequal(res$K, c(50, 200))
  expect_setequal(res$model_id, c("m1", "m2"))
})

test_that("alloscore_model_out returns one row per unit and budget when unsummarized", {
  res <- alloscore_model_out(
    mini_model_out(),
    mini_oracle_out(),
    K = c(50, 200),
    target_cols = "location",
    summarize = FALSE
  )
  expect_equal(nrow(res), 4)
  expect_true(all(
    c("model_id", "K", "score", "score_raw", "score_oracle", "ytot", "xdf") %in%
      names(res)
  ))
  expect_equal(res$score, res$score_raw - res$score_oracle)
})

test_that("alloscore_model_out summarizes by the requested columns", {
  res <- alloscore_model_out(
    mini_model_out(),
    mini_oracle_out(),
    K = c(50, 200),
    target_cols = "location",
    by = c("model_id", "K")
  )
  expect_equal(nrow(res), 4)
  expect_setequal(
    names(res),
    c("model_id", "K", "score", "score_raw", "score_oracle", "ytot")
  )
  # summarizing by model alone averages over budgets
  by_model <- alloscore_model_out(
    mini_model_out(),
    mini_oracle_out(),
    K = c(50, 200),
    target_cols = "location",
    by = "model_id"
  )
  expect_equal(nrow(by_model), 2)
})

test_that("the summarized scores are the means of the unsummarized ones", {
  args <- list(
    mini_model_out(),
    mini_oracle_out(),
    K = c(50, 200),
    target_cols = "location"
  )
  raw <- do.call(alloscore_model_out, c(args, list(summarize = FALSE)))
  summ <- do.call(alloscore_model_out, c(args, list(by = "model_id")))
  expected <- dplyr::summarise(
    dplyr::group_by(raw, .data$model_id),
    score = mean(.data$score),
    .groups = "drop"
  )
  expect_equal(summ$score, expected$score)
})

test_that("alloscore_model_out validates by", {
  expect_error(
    alloscore_model_out(
      mini_model_out(),
      mini_oracle_out(),
      K = 50,
      target_cols = "location",
      by = "nonsense"
    ),
    regexp = "not available"
  )
})

test_that("alloscore_model_out passes weights through", {
  # target b needs far more than target a, so weighting b up shifts the score
  cheap <- alloscore_model_out(
    mini_model_out(),
    mini_oracle_out(),
    K = 100,
    target_cols = "location",
    w = 1,
    summarize = FALSE
  )
  dear <- alloscore_model_out(
    mini_model_out(),
    mini_oracle_out(),
    K = 100,
    target_cols = "location",
    w = c(a = 1, b = 5),
    summarize = FALSE
  )
  expect_false(isTRUE(all.equal(cheap$score_raw, dear$score_raw)))
})

test_that("alloscore_model_out honors against_oracle", {
  res <- alloscore_model_out(
    mini_model_out(),
    mini_oracle_out(),
    K = 50,
    target_cols = "location",
    against_oracle = FALSE,
    summarize = FALSE
  )
  expect_true("score_raw" %in% names(res))
  expect_false("score" %in% names(res))
})

test_that("alloscore_model_out matches the core API on a single unit", {
  # one allocation unit routed both ways must give the same score
  mot <- dplyr::filter(mini_model_out(), .data$model_id == "m1")
  hub <- alloscore_model_out(
    mot,
    mini_oracle_out(),
    K = c(50, 200),
    target_cols = "location",
    summarize = FALSE
  )
  adf <- as_alloscore_df(mot, mini_oracle_out(), target_cols = "location")
  fc <- adf$forecasts[[1]]
  core <- alloscore(
    df = fc,
    y = rlang::set_names(fc$y, fc$target_names),
    K = c(50, 200),
    target_names = "target_names"
  )
  expect_equal(hub$score, core$score)
  expect_equal(hub$score_raw, core$score_raw)
  expect_equal(hub$ytot, core$ytot)
})

test_that("alloscore_model_out rejects unfiltered model output", {
  mot <- dplyr::bind_rows(
    mini_model_out(),
    dplyr::mutate(mini_model_out(), output_type = "mean")
  )
  expect_error(
    alloscore_model_out(
      mot,
      mini_oracle_out(),
      K = 50,
      target_cols = "location"
    ),
    regexp = "must contain a single"
  )
})
