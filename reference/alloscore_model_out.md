# Score hubverse model output with an allocation scoring rule

For each allocation unit of a hubverse model output table, allocates a
budget under the model's forecasts and scores the realized loss of that
allocation relative to the loss of an oracle that knew the observed
outcomes. See
[`as_alloscore_df()`](https://reichlab.io/alloscore2/reference/as_alloscore_df.md)
for how allocation units are determined, and
[`alloscore()`](https://reichlab.io/alloscore2/reference/alloscore.md)
for the score itself.

## Usage

``` r
alloscore_model_out(
  model_out_tbl,
  oracle_output,
  K,
  target_cols,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  against_oracle = TRUE,
  summarize = TRUE,
  by = c("model_id", "K"),
  ...
)
```

## Arguments

- model_out_tbl:

  a hubverse model output table containing a single `output_type`, which
  must be `"quantile"`.

- oracle_output:

  hubverse oracle output, holding the observed values in an
  `oracle_value` column. Optional when only allocating.

- K:

  vector of budgets. Cannot be supplied via `df`.

- target_cols:

  character vector naming the task ID columns whose combinations
  enumerate the targets that share a budget, for example `"location"`.

- w:

  allocation weights: a scalar, a vector named by target, a vector
  ordered as the targets of each allocation problem, or the name of a
  column of `model_out_tbl` holding a per-target weight.

- kappa:

  scale factor.

- alpha:

  normalized loss when the outcome `y` exceeds the allocation `x`.
  Exactly one of `alpha` and `U` must be supplied.

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

- against_oracle:

  logical; if `TRUE`, scores relative to the oracle allocation are
  included.

- summarize:

  logical; if `TRUE`, average the scores over the columns named in `by`.

- by:

  character vector naming the columns to summarize by. Must be a subset
  of the allocation unit columns and `"K"`.

- ...:

  further arguments passed to
  [`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md).

## Value

A tibble of scores. Unsummarized, one row per allocation unit and value
of `K`, with columns `K`, `score`, `score_raw`, `score_oracle`, `ytot`
and a nested `xdf` of per-target detail. Summarized, one row per
combination of `by` with the mean of each score.

## Examples

``` r
mot <- dplyr::filter(hubExamples::forecast_outputs, output_type == "quantile")
scores <- alloscore_model_out(
  model_out_tbl = mot,
  oracle_output = hubExamples::forecast_oracle_output,
  K = c(500, 1000),
  target_cols = "location",
  by = c("model_id", "K")
)
scores
#> # A tibble: 6 × 6
#>   model_id              K    score score_raw score_oracle  ytot
#>   <chr>             <dbl>    <dbl>     <dbl>        <dbl> <dbl>
#> 1 Flusight-baseline   500 -0.00553     1544.        1544. 2044.
#> 2 Flusight-baseline  1000  0.342       1045.        1044. 2044.
#> 3 MOBS-GLEAM_FLUH     500 -0.427       1544.        1544. 2044.
#> 4 MOBS-GLEAM_FLUH    1000 -0.464       1044.        1044. 2044.
#> 5 PSI-DICE            500 -0.173       1544.        1544. 2044.
#> 6 PSI-DICE           1000 -0.263       1044.        1044. 2044.
```
