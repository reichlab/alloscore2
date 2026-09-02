scored_multi_K <- function() {
  alloscore(norm_forecasts(), y = c(4, 9, 11), K = c(10, 20, 30))
}

test_that("plot_components_slim returns a ggplot for several budgets", {
  p <- plot_components_slim(slim(scored_multi_K()))
  expect_s3_class(p, "ggplot")
  # stacked areas over K
  expect_s3_class(p$layers[[1]]$geom, "GeomArea")
})

test_that("plot_components_slim uses bars for a single budget", {
  p <- plot_components_slim(slim(alloscore(
    norm_forecasts(),
    y = c(4, 9, 11),
    K = 20
  )))
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$layers[[1]]$geom, "GeomBar")
})

test_that("plot_components_slim honors bar_positioning", {
  s <- slim(alloscore(norm_forecasts(), y = c(4, 9, 11), K = 20))
  expect_s3_class(plot_components_slim(s, bar_positioning = "dodge"), "ggplot")
  expect_error(plot_components_slim(s, bar_positioning = "nope"))
})

test_that("plot_components_slim can omit the oracle", {
  p <- plot_components_slim(slim(scored_multi_K()), show_oracle = FALSE)
  expect_s3_class(p, "ggplot")
  expect_false("oracle" %in% p$data$model)
  p2 <- plot_components_slim(slim(scored_multi_K()), show_oracle = TRUE)
  expect_true("oracle" %in% p2$data$model)
})

test_that("plot_components_slim errors when asked for an oracle that was not scored", {
  s <- slim(alloscore(
    norm_forecasts(),
    y = c(4, 9, 11),
    K = c(10, 20),
    against_oracle = FALSE
  ))
  expect_error(
    plot_components_slim(s, show_oracle = TRUE),
    regexp = "no oracle components"
  )
})

test_that("plot_components_slim filters to the requested budgets", {
  p <- plot_components_slim(
    slim(scored_multi_K()),
    Ks = c(10, 20),
    show_oracle = FALSE
  )
  expect_setequal(unique(p$data$K), c(10, 20))
})

test_that("plot_components_slim accepts an ordering slice", {
  p <- plot_components_slim(slim(scored_multi_K()), order_at_K = 20)
  expect_s3_class(p, "ggplot")
})

test_that("plot_components dispatches on an allocated object", {
  p <- plot_components(scored_multi_K())
  expect_s3_class(p, "ggplot")
})

test_that("plot_components rejects unscored allocations", {
  expect_error(
    plot_components(allocate(norm_forecasts(), K = 20)),
    regexp = "must be scored"
  )
})

test_that("plot_components needs a way to tell several allocations apart", {
  a <- scored_multi_K()
  expect_error(plot_components(a, a), regexp = "nothing to tell them apart")
})

test_that("plot_components distinguishes allocations by a model column", {
  a1 <- dplyr::mutate(scored_multi_K(), model_id = "m1")
  a2 <- dplyr::mutate(scored_multi_K(), model_id = "m2")
  p <- plot_components(a1, a2, model_col_name = "model_id")
  expect_s3_class(p, "ggplot")
  expect_true(all(c("m1", "m2") %in% p$data$model))
})

test_that("plot_components rejects duplicated allocations", {
  a1 <- dplyr::mutate(scored_multi_K(), model_id = "m1")
  expect_error(
    plot_components(a1, a1, model_col_name = "model_id"),
    regexp = "not uniquely identified"
  )
})

test_that("plot_components.default reads scored allocations from a list column", {
  nested <- tibble::tibble(
    model_id = c("m1", "m2"),
    scored = list(scored_multi_K(), scored_multi_K())
  )
  p <- plot_components(nested, model_col_name = "model_id")
  expect_s3_class(p, "ggplot")
  expect_true(all(c("m1", "m2") %in% p$data$model))
})

test_that("plot_components.default errors on a missing list column", {
  expect_error(
    plot_components(tibble::tibble(x = 1)),
    regexp = "No scored allocations found"
  )
})

test_that("plot_scores_slim plots the score against the budget", {
  p <- plot_scores_slim(slim(alloscore(
    norm_forecasts(),
    y = c(4, 9, 11),
    K = seq(5, 40, 5)
  )))
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$layers[[1]]$geom, "GeomLine")
})

test_that("plot_scores_slim adds a ytot reference line", {
  s <- slim(alloscore(norm_forecasts(), y = c(4, 9, 11), K = seq(5, 40, 5)))
  with_line <- plot_scores_slim(s, ytot = TRUE)
  without <- plot_scores_slim(s, ytot = FALSE)
  expect_gt(length(with_line$layers), length(without$layers))
})

test_that("plot_scores_slim accepts a palette and line types", {
  s <- slim(alloscore(norm_forecasts(), y = c(4, 9, 11), K = seq(5, 40, 5)))
  p <- plot_scores_slim(
    s,
    palette = c(model = "red"),
    linetypes = c(model = "dashed")
  )
  expect_s3_class(p, "ggplot")
})

test_that("plot_scores_slim requires one budget per origin time for a time series", {
  s <- slim(alloscore(norm_forecasts(), y = c(4, 9, 11), K = c(10, 20)))
  s$reference_date <- as.Date("2024-01-06")
  expect_error(
    plot_scores_slim(
      s,
      ts = TRUE,
      origin_time_col_name = "reference_date",
      Ks = c(10, 20)
    ),
    regexp = "one budget per origin time"
  )
})

test_that("plot_scores_slim draws a time series when given one budget per origin time", {
  s1 <- slim(alloscore(norm_forecasts(), y = c(4, 9, 11), K = 20))
  s1$reference_date <- as.Date("2024-01-06")
  s2 <- slim(alloscore(norm_forecasts(), y = c(5, 8, 12), K = 30))
  s2$reference_date <- as.Date("2024-01-13")
  s <- dplyr::bind_rows(s1, s2)
  p <- plot_scores_slim(
    s,
    ts = TRUE,
    origin_time_col_name = "reference_date",
    Ks = c(20, 30)
  )
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$layers[[1]]$geom, "GeomLine")
})

test_that("plot_iterations returns stacked panels", {
  p <- plot_iterations(allocate(norm_forecasts(), K = 20, alpha = 0.9))
  expect_s3_class(p, "patchwork")
})

test_that("plot_iterations needs a budget when there are several", {
  a <- allocate(norm_forecasts(), K = c(10, 20), alpha = 0.9)
  expect_error(plot_iterations(a), regexp = "must be given when")
  expect_s3_class(plot_iterations(a, K_to_plot = 20), "patchwork")
  expect_error(
    plot_iterations(a, K_to_plot = 99),
    regexp = "is not among the budgets"
  )
})

test_that("plot_iterations validates itnum", {
  a <- allocate(norm_forecasts(), K = 20, alpha = 0.9)
  expect_error(
    plot_iterations(a, itnum = 999),
    regexp = "not among the iterations"
  )
  expect_s3_class(plot_iterations(a, itnum = 2), "patchwork")
})

test_that("plot_iterations rejects objects with no allocation search", {
  expect_error(
    plot_iterations(tibble::tibble(K = 1)),
    regexp = "does not hold an allocation search"
  )
})

test_that("plot_iterations works on allocate_model_out output", {
  # a flat tibble, with no target_col_name attribute to fall back on
  alloc <- allocate_model_out(
    mini_model_out(),
    K = 200,
    target_cols = "location"
  )
  one <- dplyr::filter(alloc, .data$model_id == "m1")
  expect_s3_class(plot_iterations(one, K_to_plot = 200), "patchwork")
  # and it refuses an ambiguous subset
  expect_error(
    plot_iterations(alloc, K_to_plot = 200),
    regexp = "allocations share the budget"
  )
})

test_that("plot_iterations pools targets beyond num_targets_to_color", {
  fc <- lnorm_forecasts(n = 10)
  p <- plot_iterations(
    allocate(fc, K = 300, alpha = 0.9),
    num_targets_to_color = 3
  )
  expect_s3_class(p, "patchwork")
})
