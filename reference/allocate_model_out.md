# Allocate a budget across hubverse model output

Runs
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md)
once per allocation unit of a hubverse model output table. See
[`as_alloscore_df()`](https://reichlab.io/alloscore2/reference/as_alloscore_df.md)
for how allocation units are determined.

## Usage

``` r
allocate_model_out(
  model_out_tbl,
  K,
  target_cols,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  ...
)
```

## Arguments

- model_out_tbl:

  a hubverse model output table containing a single `output_type`, which
  must be `"quantile"`.

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

- ...:

  further arguments passed to
  [`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md).

## Value

A tibble with one row per allocation unit and value of `K`, holding the
allocation unit columns and the columns returned by
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md).
Unlike
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md)
this is a plain tibble rather than an `allocated` object, since each
unit has its own loss functions and weights. A single row of it can
still be passed to
[`plot_iterations()`](https://reichlab.io/alloscore2/reference/plot_iterations.md).

## Examples

``` r
mot <- dplyr::filter(
  hubExamples::forecast_outputs,
  output_type == "quantile", reference_date == "2022-11-19", horizon == 0
)
allocate_model_out(mot, K = c(100, 500), target_cols = "location")
#> # A tibble: 6 × 17
#>   model_id    reference_date target horizon target_end_date     K xs       x    
#>   <chr>       <date>         <chr>    <int> <date>          <dbl> <list>   <lis>
#> 1 Flusight-b… 2022-11-19     wk in…       0 2022-11-19        100 <gpl_df> <dbl>
#> 2 Flusight-b… 2022-11-19     wk in…       0 2022-11-19        500 <gpl_df> <dbl>
#> 3 MOBS-GLEAM… 2022-11-19     wk in…       0 2022-11-19        100 <gpl_df> <dbl>
#> 4 MOBS-GLEAM… 2022-11-19     wk in…       0 2022-11-19        500 <gpl_df> <dbl>
#> 5 PSI-DICE    2022-11-19     wk in…       0 2022-11-19        100 <gpl_df> <dbl>
#> 6 PSI-DICE    2022-11-19     wk in…       0 2022-11-19        500 <gpl_df> <dbl>
#> # ℹ 9 more variables: qs_OK <lgl>, lamL <dbl>, lamL_seq <list>, lamU <dbl>,
#> #   lamU_seq <list>, lam <dbl>, lam_seq <list>, post_processed <lgl>,
#> #   xdf <list>
```
