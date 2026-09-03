# Drop the heavy list columns of an allocated data frame

An `allocated` object carries the full lambda-iteration history and a
closure per target, which is far more than is needed to score many
outcome vectors against the same allocation. `slim()` keeps the budgets,
the allocations and the scores.

## Usage

``` r
slim(
  adf,
  xdf_action = c("default", "unnest", "nest"),
  id_cols = NULL,
  rm_score_fun_if_scored = TRUE,
  rm_score_fun_if_not_scored = FALSE
)
```

## Arguments

- adf:

  an `allocated` object, as returned by
  [`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md).

- xdf_action:

  whether to unnest the `xdf` column. The default unnests an unscored
  allocation and leaves a scored one nested.

- id_cols:

  additional columns to keep, such as a model name or origin time.

- rm_score_fun_if_scored:

  drop the per-target scoring closure from a scored data frame, where it
  is usually no longer needed.

- rm_score_fun_if_not_scored:

  drop the per-target scoring closure from an unscored data frame.
  Defaults to `FALSE`, since it is what
  [`alloscore.slim()`](https://reichlab.io/alloscore2/reference/alloscore.md)
  scores with.

## Value

A tibble of class `slim`, carrying the `gpl_df`, `w` and
`target_col_name` attributes of `adf`.

## Examples

``` r
fc <- add_pdqr_funs(
  tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
  types = c("p", "q")
)
slim(allocate(fc, K = c(10, 20)))
#> # A tibble: 4 × 4
#>       K target_names     x score_fun
#> * <dbl> <chr>        <dbl> <list>   
#> 1    10 a             3.50 <fn>     
#> 2    10 b             6.50 <fn>     
#> 3    20 a             8.50 <fn>     
#> 4    20 b            11.5  <fn>     
```
