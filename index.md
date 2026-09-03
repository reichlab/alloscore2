# alloscore2

`alloscore2` scores probabilistic forecasts by what they would have done
with a scarce resource.

Given forecasts for several targets and a shared budget `K`, it
allocates that budget to minimize expected loss, then scores the
forecasts by the loss the allocation actually incurred, relative to the
loss of an allocation made by an oracle that knew the outcomes in
advance. A forecast that would have directed resources well scores near
zero; one that would have misdirected them scores badly, however good
its marginal calibration looks.

It reads [hubverse](https://hubverse.io) model output and target data
directly. It is a rewrite of the original
[alloscore](https://github.com/aaronger/alloscore) package by Aaron
Gerding, and reproduces its numerical results; see
`tests/testthat/test-legacy-equivalence.R`.

## Installation

``` r

remotes::install_github("reichlab/alloscore2")
```

## Getting started

[`vignette("alloscore2")`](https://reichlab.io/alloscore2/articles/alloscore2.md)
— [read it
online](https://reichlab.io/alloscore2/articles/alloscore2.html) — is
the guided tour: choosing which targets share a budget, reading the
scores and their per-target decomposition, varying the unit costs `w`
and the asymmetry `alpha`, and looking inside the optimization with the
plotting functions. The sections below are the short version.

## Scoring hubverse model output

[`alloscore_model_out()`](https://reichlab.io/alloscore2/reference/alloscore_model_out.md)
takes a `model_out_tbl` of quantile forecasts and the matching
`oracle_output`. The one thing you have to tell it is which task ID
columns enumerate the targets that *share* a budget — here the
locations, so each model, reference date and horizon is a separate
allocation problem.

``` r

library(alloscore2)
library(dplyr)

model_out <- hubExamples::forecast_outputs |>
  filter(output_type == "quantile")

scores <- alloscore_model_out(
  model_out_tbl = model_out,
  oracle_output = hubExamples::forecast_oracle_output,
  K = c(500, 1000, 2000),
  target_cols = "location",
  by = c("model_id", "K")
)
scores
#> # A tibble: 9 × 6
#>   model_id              K    score score_raw score_oracle  ytot
#>   <chr>             <dbl>    <dbl>     <dbl>        <dbl> <dbl>
#> 1 Flusight-baseline   500 -0.00553     1544.        1544. 2044.
#> 2 Flusight-baseline  1000  0.342       1045.        1044. 2044.
#> 3 Flusight-baseline  2000 50.7          228.         177. 2044.
#> 4 MOBS-GLEAM_FLUH     500 -0.427       1544.        1544. 2044.
#> 5 MOBS-GLEAM_FLUH    1000 -0.464       1044.        1044. 2044.
#> 6 MOBS-GLEAM_FLUH    2000 29.4          207.         177. 2044.
#> 7 PSI-DICE            500 -0.173       1544.        1544. 2044.
#> 8 PSI-DICE           1000 -0.263       1044.        1044. 2044.
#> 9 PSI-DICE           2000 53.1          230.         177. 2044.
```

The score is the realized loss less the oracle’s, so smaller is better.
Because the budget is shared across locations, a model is rewarded for
getting the *relative* burden across locations right, not just each
location on its own.

Passing `summarize = FALSE` returns one row per allocation problem, with
a nested `xdf` column holding each target’s allocation, outcome and
loss:

``` r

detail <- alloscore_model_out(
  model_out_tbl = model_out,
  oracle_output = hubExamples::forecast_oracle_output,
  K = 1000,
  target_cols = "location",
  summarize = FALSE
)
detail$xdf[[1]]
#> # A tibble: 2 × 8
#>   target_names     x score_fun     y oracle components_raw components_oracle components
#>   <chr>        <dbl> <list>    <dbl>  <dbl>          <dbl>             <dbl>      <dbl>
#> 1 25            32.3 <fn>         79   73.2           46.7              5.78       40.9
#> 2 48           968.  <fn>       1230  927.           262.             303.        -40.9
```

## Allocating without scoring

[`allocate_model_out()`](https://reichlab.io/alloscore2/reference/allocate_model_out.md)
stops after the allocation, which is useful when the question is what a
forecast implies you should do rather than how good it was:

``` r

allocate_model_out(
  model_out_tbl = filter(model_out, reference_date == "2022-11-19", horizon == 0),
  K = 1000,
  target_cols = "location"
) |>
  select(model_id, K, xdf) |>
  mutate(allocations = purrr::map(xdf, ~ select(.x, target_names, x))) |>
  select(-xdf) |>
  tidyr::unnest(allocations)
#> # A tibble: 6 × 4
#>   model_id              K target_names     x
#>   <chr>             <dbl> <chr>        <dbl>
#> 1 Flusight-baseline  1000 25            32.3
#> 2 Flusight-baseline  1000 48           968. 
#> 3 MOBS-GLEAM_FLUH    1000 25            30.2
#> 4 MOBS-GLEAM_FLUH    1000 48           970. 
#> 5 PSI-DICE           1000 25            32.5
#> 6 PSI-DICE           1000 48           967.
```

## Working outside the hubverse

The allocation machinery does not require hub data. Forecasts can be
given as any parametric family, with
[`add_pdqr_funs()`](https://reichlab.io/alloscore2/reference/add_pdqr_funs.md)
building the cdfs and quantile functions from parameter columns:

``` r

forecasts <- add_pdqr_funs(
  tibble::tibble(
    target_names = c("a", "b", "c"),
    dist = "norm",
    mean = c(5, 8, 12),
    sd = c(1, 2, 3)
  ),
  types = c("p", "q")
)

alloscore(forecasts, y = c(4, 9, 11), K = c(10, 20, 30)) |>
  select(K, score, score_raw, score_oracle)
#> # A tibble: 3 × 4
#>       K  score score_raw score_oracle
#>   <dbl>  <dbl>     <dbl>        <dbl>
#> 1    10 0.0154     14.0            14
#> 2    20 0.167       4.17            4
#> 3    30 0           0               0
```

The loss is a generalized piecewise linear (pinball) loss, so `alpha`
sets how much worse it is to under-allocate than to over-allocate,
`kappa` scales it, and `w` gives the cost per unit allocated to each
target. The
[`stdize_news_params()`](https://reichlab.io/alloscore2/reference/stdize_news_params.md),
[`stdize_ou_params()`](https://reichlab.io/alloscore2/reference/stdize_ou_params.md)
and
[`stdize_met_params()`](https://reichlab.io/alloscore2/reference/stdize_met_params.md)
helpers convert the newsvendor, over/under-cost and cost-loss
parameterizations into `kappa` and `alpha`.

## Validation

The `zxh_tab2` and `zxh_tab3` datasets carry the published optima of two
budget-constrained multiproduct newsboy problems from Zhang, Xu and Hua
(2009), which
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md)
reproduces. See
[`vignette("zxh-newsvendor")`](https://reichlab.io/alloscore2/articles/zxh-newsvendor.md).

## Code of Conduct

Please note that this package is released with a [Contributor Code of
Conduct](https://reichlab.io/alloscore2/CODE_OF_CONDUCT.md). By
contributing to this project, you agree to abide by its terms.

## Contributing

Interested in contributing back to the project? Please see our
[contributing
guidelines](https://reichlab.io/alloscore2/CONTRIBUTING.md).
