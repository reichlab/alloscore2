# Convert hubverse model output into forecasts alloscore2 can allocate against

Groups a hubverse model output table into allocation problems, turns
each target's predictive quantiles into a cdf and quantile function
using
[`distfromq::make_p_fn()`](http://reichlab.io/distfromq/reference/make_p_fn.md)
and
[`distfromq::make_q_fn()`](http://reichlab.io/distfromq/reference/make_q_fn.md),
and attaches the observed outcomes from `oracle_output`.

## Usage

``` r
as_alloscore_df(model_out_tbl, oracle_output = NULL, target_cols)
```

## Arguments

- model_out_tbl:

  a hubverse model output table containing a single `output_type`, which
  must be `"quantile"`.

- oracle_output:

  hubverse oracle output, holding the observed values in an
  `oracle_value` column. Optional when only allocating.

- target_cols:

  character vector naming the task ID columns whose combinations
  enumerate the targets that share a budget, for example `"location"`.

## Value

A tibble with one row per allocation unit, the allocation unit columns,
and a `forecasts` list column. Each element of `forecasts` is a tibble
with one row per target holding the `target_cols`, a `target_names` key,
the predictive quantile levels `ps` and values `qs`, the cdf `F` and
quantile function `Q`, and – when `oracle_output` was supplied – the
observed outcome `y`.

## Details

An allocation problem is a set of targets that share one budget.
`target_cols` names the task ID columns whose combinations enumerate
those targets; every other task ID column, together with `model_id`,
defines the *allocation unit*, and one allocation problem is solved per
combination of those. This mirrors the way a hubverse
`compound_taskid_set` distinguishes task IDs that vary within a group
from those held constant.

## Examples

``` r
mot <- dplyr::filter(hubExamples::forecast_outputs, output_type == "quantile")
adf <- as_alloscore_df(
  mot,
  oracle_output = hubExamples::forecast_oracle_output,
  target_cols = "location"
)
adf
#> # A tibble: 24 × 6
#>    model_id          reference_date target     horizon target_end_date forecasts
#>  * <chr>             <date>         <chr>        <int> <date>          <list>   
#>  1 Flusight-baseline 2022-11-19     wk inc fl…       0 2022-11-19      <tibble> 
#>  2 Flusight-baseline 2022-11-19     wk inc fl…       1 2022-11-26      <tibble> 
#>  3 Flusight-baseline 2022-11-19     wk inc fl…       2 2022-12-03      <tibble> 
#>  4 Flusight-baseline 2022-11-19     wk inc fl…       3 2022-12-10      <tibble> 
#>  5 Flusight-baseline 2022-12-17     wk inc fl…       0 2022-12-17      <tibble> 
#>  6 Flusight-baseline 2022-12-17     wk inc fl…       1 2022-12-24      <tibble> 
#>  7 Flusight-baseline 2022-12-17     wk inc fl…       2 2022-12-31      <tibble> 
#>  8 Flusight-baseline 2022-12-17     wk inc fl…       3 2023-01-07      <tibble> 
#>  9 MOBS-GLEAM_FLUH   2022-11-19     wk inc fl…       0 2022-11-19      <tibble> 
#> 10 MOBS-GLEAM_FLUH   2022-11-19     wk inc fl…       1 2022-11-26      <tibble> 
#> # ℹ 14 more rows
adf$forecasts[[1]]
#> # A tibble: 2 × 7
#>   location target_names     y ps        qs        F      Q     
#>   <chr>    <chr>        <dbl> <list>    <list>    <list> <list>
#> 1 25       25              79 <dbl [7]> <dbl [7]> <fn>   <fn>  
#> 2 48       48            1230 <dbl [7]> <dbl [7]> <fn>   <fn>  
```
