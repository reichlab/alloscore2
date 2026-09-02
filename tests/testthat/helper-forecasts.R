# Fixtures shared across test files.

# A small set of normal forecasts, one row per target.
norm_forecasts <- function(means = c(5, 8, 12), sds = c(1, 2, 3)) {
  add_pdqr_funs(
    tibble::tibble(
      target_names = LETTERS[seq_along(means)],
      dist = "norm",
      mean = means,
      sd = sds
    ),
    types = c("p", "q")
  )
}

# The lognormal forecasts used by the legacy reference fixtures.
lnorm_forecasts <- function(n = 10, y_mean = 50) {
  add_pdqr_funs(
    tibble::tibble(
      target_names = LETTERS[1:n],
      dist = "lnorm",
      sdlog = 1,
      meanlog = log(y_mean + 15 * (1:n)) - .5
    ),
    types = c("p", "q")
  )
}

# Forecasts built from predictive quantiles, as a hub would supply them.
quantile_forecasts <- function() {
  ps <- c(0.025, 0.1, 0.25, 0.5, 0.75, 0.9, 0.975)
  add_pdqr_funs(
    tibble::tibble(
      target_names = c("A", "B", "C"),
      dist = "distfromq",
      ps = list(ps, ps, ps),
      qs = list(
        c(10, 15, 22, 30, 41, 55, 70),
        c(5, 8, 12, 18, 26, 36, 48),
        c(20, 28, 38, 50, 64, 80, 100)
      )
    ),
    types = c("p", "q")
  )
}

# The ZXH Table 2 newsvendor example, ready to allocate.
zxh_norm_forecasts <- function() {
  ex <- dplyr::mutate(
    tibble::as_tibble(alloscore2::zxh_tab2),
    stdize_news_params(ax = .data$c, a_minus = .data$v, a_plus = .data$h),
    .after = "c"
  )
  add_pdqr_funs(
    dplyr::rename(ex, mean = "mu", sd = "sigma"),
    dist = "norm",
    types = c("p", "q")
  )
}

# The ZXH Table 3 newsvendor example, on a rescaled beta support.
zxh_beta_forecasts <- function() {
  ex <- dplyr::mutate(
    tibble::as_tibble(alloscore2::zxh_tab3),
    stdize_news_params(ax = .data$c, a_minus = .data$v, a_plus = .data$h),
    .after = "c"
  )
  add_pdqr_funs(
    dplyr::rename(ex, shape1 = "Balpha", shape2 = "Bbeta"),
    types = c("p", "q"),
    dist = "beta",
    trans = function(x, x_min, x_max) (x - x_min) / (x_max - x_min),
    trans_inv = function(q, x_min, x_max) x_min + (x_max - x_min) * q
  )
}

# A minimal hubverse model output table with a single quantile forecast set.
mini_model_out <- function() {
  ps <- c(0.1, 0.25, 0.5, 0.75, 0.9)
  tidyr::expand_grid(
    model_id = c("m1", "m2"),
    reference_date = as.Date("2024-01-06"),
    horizon = 1L,
    location = c("a", "b"),
    output_type_id = ps
  ) |>
    dplyr::mutate(
      target = "inc hosp",
      target_end_date = .data$reference_date + 7L * .data$horizon,
      output_type = "quantile",
      value = qnorm(
        .data$output_type_id,
        mean = ifelse(.data$location == "a", 50, 80) +
          ifelse(.data$model_id == "m1", 0, 10),
        sd = 10
      )
    ) |>
    dplyr::select(
      "model_id",
      "reference_date",
      "target",
      "horizon",
      "location",
      "target_end_date",
      "output_type",
      "output_type_id",
      "value"
    )
}

mini_oracle_out <- function() {
  tibble::tibble(
    location = c("a", "b"),
    target_end_date = as.Date("2024-01-13"),
    target = "inc hosp",
    output_type = "quantile",
    output_type_id = NA_character_,
    oracle_value = c(45, 95)
  )
}

# Forecasts whose probability mass lies entirely below zero, so that allocating
# anything at all has no marginal benefit.
below_zero_forecasts <- function() {
  add_pdqr_funs(
    tibble::tibble(
      target_names = LETTERS[1:3],
      dist = "norm",
      mean = c(-10, -12, -15),
      sd = 1
    ),
    types = c("p", "q")
  )
}
