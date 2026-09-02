## Generate frozen reference values from the ORIGINAL alloscore package.
##
## The original package (https://github.com/aaronger/alloscore) has no test
## suite, so there is no existing ground truth to port. This script runs the old
## code once over a fixed set of fixtures and writes the results to
## tests/testthat/testdata/, where test-legacy-equivalence.R compares them
## against alloscore2. That keeps the old package out of alloscore2's
## dependencies while still pinning the numerics.
##
## Run from the package root with the original alloscore checked out alongside:
##   Rscript data-raw/make_legacy_reference.R
##
## Regenerate only when deliberately changing what is compared; a diff in these
## files is a behaviour change and should be reviewed as one.

library(dplyr)
library(purrr)
library(tibble)
library(rlang)
library(magrittr)
library(tidyr)

OLD_PKG <- Sys.getenv("ALLOSCORE_OLD_PATH", "../alloscore")
OUT_DIR <- "tests/testthat/testdata"
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

stopifnot(dir.exists(OLD_PKG))
suppressMessages(pkgload::load_all(OLD_PKG, quiet = TRUE, export_all = TRUE))
message("Loaded original alloscore from ", normalizePath(OLD_PKG))

old_sha <- system2(
  "git",
  c("-C", OLD_PKG, "rev-parse", "HEAD"),
  stdout = TRUE,
  stderr = FALSE
)

## ---------------------------------------------------------------- fixture 1 --
## ZXH Table 2: Normal demand, K = 2500, unit cost as weight.
zxh_norm <- zxh_tab2 %>%
  mutate(stdize_news_params(ax = c, a_minus = v, a_plus = h), .after = c) %>%
  as_tibble() %>%
  rename(mean = mu, sd = sigma) %>%
  add_pdqr_funs(dist = "norm", types = c("p", "q"))
allo_norm <- allocate(zxh_norm, w = "c", K = 2500, target_names = "Product")
write.csv(
  allo_norm$xdf[[1]] %>% select(Product, x),
  file.path(OUT_DIR, "legacy_zxh_norm.csv"),
  row.names = FALSE
)

## ---------------------------------------------------------------- fixture 2 --
## ZXH Table 3: Beta demand rescaled onto [x_min, x_max], K = 6500.
zxh_beta <- zxh_tab3 %>%
  mutate(stdize_news_params(ax = c, a_minus = v, a_plus = h), .after = c) %>%
  as_tibble() %>%
  rename(shape1 = Balpha, shape2 = Bbeta) %>%
  add_pdqr_funs(
    types = c("p", "q"),
    dist = "beta",
    trans = function(x, x_min, x_max) (x - x_min) / (x_max - x_min),
    trans_inv = function(q, x_min, x_max) x_min + (x_max - x_min) * q
  )
allo_beta <- allocate(zxh_beta, w = "c", K = 6500, target_names = "Product")
write.csv(
  allo_beta$xdf[[1]] %>% select(Product, x),
  file.path(OUT_DIR, "legacy_zxh_beta.csv"),
  row.names = FALSE
)

## ---------------------------------------------------------------- fixture 3 --
## The basic_use vignette scenario: 10 lognormal forecasts against exponential
## outcomes, scored over a grid of budgets.
N <- 10
y_mean <- 50
lnorm_fc <- tibble(
  target_names = LETTERS[1:N],
  dist = "lnorm",
  sdlog = 1,
  meanlog = log(y_mean + 15 * (1:N)) - .5 * sdlog
) %>%
  add_pdqr_funs(types = c("p", "q"))
y_lnorm <- withr::with_seed(8675309, rexp(N, rate = 1 / y_mean))
saveRDS(y_lnorm, file.path(OUT_DIR, "legacy_lnorm_y.rds"))

Ks_lnorm <- seq(200, 400, by = 50)
scored_lnorm <- alloscore(df = lnorm_fc, y = y_lnorm, K = Ks_lnorm)
write.csv(
  scored_lnorm %>% select(K, score, score_raw, score_oracle, ytot),
  file.path(OUT_DIR, "legacy_lnorm_scores.csv"),
  row.names = FALSE
)
write.csv(
  scored_lnorm %>%
    select(K, xdf) %>%
    unnest(xdf) %>%
    select(
      K,
      target_names,
      x,
      y,
      oracle,
      components_raw,
      components_oracle,
      components
    ),
  file.path(OUT_DIR, "legacy_lnorm_components.csv"),
  row.names = FALSE
)

## ---------------------------------------------------------------- fixture 4 --
## The critical fixture: hubverse quantile forecasts pushed through the OLD
## package's hand-rolled pipeline, exactly as utility-eval-papers/R/run-alloscore.R
## does it. alloscore2's as_alloscore_df() / alloscore_model_out() must
## reproduce these numbers.
mot <- hubExamples::forecast_outputs %>%
  filter(output_type == "quantile")
oracle <- hubExamples::forecast_oracle_output %>%
  filter(output_type == "quantile") %>%
  select(-output_type, -output_type_id)

unit_cols <- c(
  "model_id",
  "reference_date",
  "target",
  "horizon",
  "target_end_date"
)
Ks_hub <- c(200, 800, 2000)

hub_nested <- mot %>%
  arrange(
    across(all_of(c(unit_cols, "location"))),
    as.numeric(output_type_id)
  ) %>%
  group_by(across(all_of(c(unit_cols, "location")))) %>%
  summarise(
    ps = list(as.numeric(output_type_id)),
    qs = list(value),
    .groups = "drop"
  ) %>%
  left_join(oracle, by = c("location", "target_end_date", "target")) %>%
  rename(y = oracle_value)

hub_rows <- hub_nested %>%
  group_by(across(all_of(unit_cols))) %>%
  group_split()

hub_scores <- map(hub_rows, function(unit) {
  fc <- unit %>%
    mutate(target_names = as.character(location), dist = "distfromq") %>%
    add_pdqr_funs(types = c("p", "q"))
  scored <- alloscore(
    df = fc,
    y = set_names(fc$y, fc$target_names),
    K = Ks_hub,
    target_names = "target_names"
  )
  bind_cols(
    unit[rep(1L, nrow(scored)), unit_cols, drop = FALSE],
    scored %>% select(K, score, score_raw, score_oracle, ytot)
  )
}) %>%
  list_rbind()
write.csv(
  hub_scores,
  file.path(OUT_DIR, "legacy_hub_quantile_scores.csv"),
  row.names = FALSE
)

hub_components <- map(hub_rows, function(unit) {
  fc <- unit %>%
    mutate(target_names = as.character(location), dist = "distfromq") %>%
    add_pdqr_funs(types = c("p", "q"))
  scored <- alloscore(
    df = fc,
    y = set_names(fc$y, fc$target_names),
    K = Ks_hub,
    target_names = "target_names"
  )
  detail <- scored %>%
    select(K, xdf) %>%
    unnest(xdf) %>%
    select(
      K,
      target_names,
      x,
      y,
      oracle,
      components_raw,
      components_oracle,
      components
    )
  bind_cols(
    unit[rep(1L, nrow(detail)), unit_cols, drop = FALSE],
    detail
  )
}) %>%
  list_rbind()
write.csv(
  hub_components,
  file.path(OUT_DIR, "legacy_hub_quantile_components.csv"),
  row.names = FALSE
)

## ---------------------------------------------------------------- fixture 5 --
## The Monte Carlo `slim` path over several outcome vectors.
Ks_slim <- c(150, 400)
allo_slim <- slim(allocate(lnorm_fc, K = Ks_slim))
ys_slim <- withr::with_seed(20240101, {
  map(1:4, function(i) set_names(rexp(N, rate = 1 / y_mean), LETTERS[1:N]))
})
saveRDS(ys_slim, file.path(OUT_DIR, "legacy_slim_ys.rds"))
slim_scored <- alloscore(allo_slim, ys_slim)
write.csv(
  slim_scored %>% select(samp, scores) %>% unnest(scores),
  file.path(OUT_DIR, "legacy_slim_scores.csv"),
  row.names = FALSE
)

## ------------------------------------------------------------------ metadata --
meta <- list(
  generated_on = as.character(Sys.Date()),
  old_alloscore_git_sha = old_sha,
  r_version = R.version.string,
  distfromq_version = as.character(packageVersion("distfromq")),
  hubExamples_version = as.character(packageVersion("hubExamples")),
  Ks_lnorm = Ks_lnorm,
  Ks_hub = Ks_hub,
  Ks_slim = Ks_slim
)
writeLines(
  jsonlite::toJSON(meta, auto_unbox = TRUE, pretty = TRUE),
  file.path(OUT_DIR, "legacy_reference_meta.json")
)

message("Wrote reference fixtures to ", OUT_DIR)
