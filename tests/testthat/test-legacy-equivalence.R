# Equivalence with the original alloscore package.
#
# The original package (aaronger/alloscore) has no test suite, so there is no
# pre-existing ground truth to port. data-raw/make_legacy_reference.R runs the
# original code once over a fixed set of fixtures and freezes the results in
# testdata/; these tests check that alloscore2 reproduces them. That keeps the
# original package out of this one's dependencies while still pinning the
# numerics, so any future change in behaviour has to be deliberate.
#
# See testdata/legacy_reference_meta.json for the original package's git SHA and
# the versions everything was generated under.
#
# Tolerances are loose enough to absorb root-finding noise but far tighter than
# any behavioural difference would be: allocations to 1e-6, scores to 1e-8.
ALLOC_TOL <- 1e-6
SCORE_TOL <- 1e-8

read_legacy <- function(file) {
  read.csv(test_path("testdata", file), stringsAsFactors = FALSE)
}

test_that("the reference fixtures are present and were generated together", {
  meta <- jsonlite::fromJSON(test_path(
    "testdata",
    "legacy_reference_meta.json"
  ))
  expect_equal(
    meta$old_alloscore_git_sha,
    "0477ae9ed97da8fe1fa754e1c3452516aafb3fd9"
  )
  expect_true(all(c("Ks_lnorm", "Ks_hub", "Ks_slim") %in% names(meta)))
})

test_that("ZXH Table 2 allocations match the original package", {
  legacy <- read_legacy("legacy_zxh_norm.csv")
  a <- allocate(
    zxh_norm_forecasts(),
    w = "c",
    K = 2500,
    target_names = "Product"
  )
  ours <- a$xdf[[1]]
  expect_equal(as.character(ours$Product), as.character(legacy$Product))
  expect_equal(ours$x, legacy$x, tolerance = ALLOC_TOL, ignore_attr = TRUE)
})

test_that("ZXH Table 3 allocations match the original package", {
  legacy <- read_legacy("legacy_zxh_beta.csv")
  a <- allocate(
    zxh_beta_forecasts(),
    w = "c",
    K = 6500,
    target_names = "Product"
  )
  ours <- a$xdf[[1]]
  expect_equal(as.character(ours$Product), as.character(legacy$Product))
  expect_equal(ours$x, legacy$x, tolerance = ALLOC_TOL, ignore_attr = TRUE)
})

test_that("lognormal scores match the original package", {
  legacy <- read_legacy("legacy_lnorm_scores.csv")
  y <- readRDS(test_path("testdata", "legacy_lnorm_y.rds"))
  ours <- alloscore(lnorm_forecasts(), y = y, K = legacy$K)
  expect_equal(ours$K, legacy$K)
  expect_equal(ours$score, legacy$score, tolerance = SCORE_TOL)
  expect_equal(ours$score_raw, legacy$score_raw, tolerance = SCORE_TOL)
  expect_equal(ours$score_oracle, legacy$score_oracle, tolerance = SCORE_TOL)
  expect_equal(ours$ytot, legacy$ytot, tolerance = SCORE_TOL)
})

test_that("lognormal per-target components match the original package", {
  legacy <- read_legacy("legacy_lnorm_components.csv")
  y <- readRDS(test_path("testdata", "legacy_lnorm_y.rds"))
  ours <- alloscore(lnorm_forecasts(), y = y, K = unique(legacy$K))
  ours <- tidyr::unnest(dplyr::select(ours, "K", "xdf"), "xdf")
  ours <- dplyr::arrange(ours, .data$K, .data$target_names)
  legacy <- dplyr::arrange(legacy, .data$K, .data$target_names)
  expect_equal(ours$target_names, legacy$target_names)
  expect_equal(ours$x, legacy$x, tolerance = ALLOC_TOL, ignore_attr = TRUE)
  expect_equal(
    ours$oracle,
    legacy$oracle,
    tolerance = ALLOC_TOL,
    ignore_attr = TRUE
  )
  expect_equal(
    ours$components_raw,
    legacy$components_raw,
    tolerance = SCORE_TOL,
    ignore_attr = TRUE
  )
  expect_equal(
    ours$components_oracle,
    legacy$components_oracle,
    tolerance = SCORE_TOL,
    ignore_attr = TRUE
  )
  expect_equal(
    ours$components,
    legacy$components,
    tolerance = SCORE_TOL,
    ignore_attr = TRUE
  )
})

test_that("the Monte Carlo slim path matches the original package", {
  legacy <- read_legacy("legacy_slim_scores.csv")
  ys <- readRDS(test_path("testdata", "legacy_slim_ys.rds"))
  a <- slim(allocate(lnorm_forecasts(), K = unique(legacy$K)))
  ours <- alloscore(a, ys)
  ours <- tidyr::unnest(dplyr::select(ours, "samp", "scores"), "scores")
  ours <- dplyr::arrange(ours, .data$samp, .data$K)
  legacy <- dplyr::arrange(legacy, .data$samp, .data$K)
  expect_equal(as.character(ours$samp), as.character(legacy$samp))
  expect_equal(ours$K, legacy$K)
  expect_equal(ours$score, legacy$score, tolerance = SCORE_TOL)
  expect_equal(ours$score_raw, legacy$score_raw, tolerance = SCORE_TOL)
  expect_equal(ours$score_oracle, legacy$score_oracle, tolerance = SCORE_TOL)
})

# The tests below are the point of the whole exercise: they check that the
# hubverse-native entry points reproduce what the original package produced when
# the same hub data was pushed through its hand-rolled pipeline (nest ps/qs,
# add_pdqr_funs(dist = "distfromq"), join truth, alloscore), as in
# utility-eval-papers/R/run-alloscore.R.

skip_if_no_hub_examples <- function() {
  skip_if_not_installed("hubExamples")
}

hub_model_out <- function() {
  dplyr::filter(hubExamples::forecast_outputs, .data$output_type == "quantile")
}

test_that("alloscore_model_out matches the original hand-rolled hub pipeline", {
  skip_if_no_hub_examples()
  legacy <- read_legacy("legacy_hub_quantile_scores.csv")
  meta <- jsonlite::fromJSON(test_path(
    "testdata",
    "legacy_reference_meta.json"
  ))

  ours <- alloscore_model_out(
    model_out_tbl = hub_model_out(),
    oracle_output = hubExamples::forecast_oracle_output,
    K = meta$Ks_hub,
    target_cols = "location",
    summarize = FALSE
  )
  key <- c("model_id", "reference_date", "target", "horizon", "K")
  ours <- dplyr::arrange(
    dplyr::mutate(ours, reference_date = as.character(.data$reference_date)),
    dplyr::pick(tidyselect::all_of(key))
  )
  legacy <- dplyr::arrange(legacy, dplyr::pick(tidyselect::all_of(key)))

  expect_equal(nrow(ours), nrow(legacy))
  expect_equal(ours$model_id, legacy$model_id)
  expect_equal(ours$reference_date, legacy$reference_date)
  expect_equal(ours$horizon, legacy$horizon)
  expect_equal(ours$K, legacy$K)
  expect_equal(ours$score, legacy$score, tolerance = SCORE_TOL)
  expect_equal(ours$score_raw, legacy$score_raw, tolerance = SCORE_TOL)
  expect_equal(ours$score_oracle, legacy$score_oracle, tolerance = SCORE_TOL)
  expect_equal(ours$ytot, legacy$ytot, tolerance = SCORE_TOL)
})

test_that("per-target hub allocations match the original hand-rolled pipeline", {
  skip_if_no_hub_examples()
  legacy <- read_legacy("legacy_hub_quantile_components.csv")
  meta <- jsonlite::fromJSON(test_path(
    "testdata",
    "legacy_reference_meta.json"
  ))

  ours <- alloscore_model_out(
    model_out_tbl = hub_model_out(),
    oracle_output = hubExamples::forecast_oracle_output,
    K = meta$Ks_hub,
    target_cols = "location",
    summarize = FALSE
  )
  ours <- tidyr::unnest(
    dplyr::select(ours, "model_id", "reference_date", "horizon", "K", "xdf"),
    "xdf"
  )
  key <- c("model_id", "reference_date", "horizon", "K", "target_names")
  ours <- dplyr::arrange(
    dplyr::mutate(
      ours,
      reference_date = as.character(.data$reference_date),
      target_names = as.character(.data$target_names)
    ),
    dplyr::pick(tidyselect::all_of(key))
  )
  legacy <- dplyr::arrange(
    dplyr::mutate(legacy, target_names = as.character(.data$target_names)),
    dplyr::pick(tidyselect::all_of(key))
  )

  expect_equal(nrow(ours), nrow(legacy))
  expect_equal(ours$target_names, legacy$target_names)
  expect_equal(ours$x, legacy$x, tolerance = ALLOC_TOL, ignore_attr = TRUE)
  expect_equal(ours$y, legacy$y, tolerance = SCORE_TOL, ignore_attr = TRUE)
  expect_equal(
    ours$oracle,
    legacy$oracle,
    tolerance = ALLOC_TOL,
    ignore_attr = TRUE
  )
  expect_equal(
    ours$components_raw,
    legacy$components_raw,
    tolerance = SCORE_TOL,
    ignore_attr = TRUE
  )
  expect_equal(
    ours$components_oracle,
    legacy$components_oracle,
    tolerance = SCORE_TOL,
    ignore_attr = TRUE
  )
  expect_equal(
    ours$components,
    legacy$components,
    tolerance = SCORE_TOL,
    ignore_attr = TRUE
  )
})
