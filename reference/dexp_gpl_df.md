# Create a list of derivatives of expected gpl losses from a `gpl_df`

Create a list of derivatives of expected gpl losses from a `gpl_df`

## Usage

``` r
dexp_gpl_df(df, F)
```

## Arguments

- df:

  a `gpl_df`, as created by
  [`new_gpl_df()`](https://reichlab.github.io/alloscore2/reference/new_gpl_df.md).

- F:

  list of predictive cdfs, one per row of `df`.

## Value

A list of functions of an allocation `x`, one per target.

## Examples

``` r
gdf <- new_gpl_df(N = 2, alpha = 0.5)
dexp_gpl_df(gdf, F = list(pnorm, pnorm))
#> [[1]]
#> function (x) 
#> {
#>     kappa * ((1 - alpha) * dexp_over_loss(dg = dg, F = F)(x) + 
#>         alpha * dexp_under_loss(dg = dg, F = F)(x))
#> }
#> <bytecode: 0x55b2ab604ab0>
#> <environment: 0x55b2b1359ec0>
#> 
#> [[2]]
#> function (x) 
#> {
#>     kappa * ((1 - alpha) * dexp_over_loss(dg = dg, F = F)(x) + 
#>         alpha * dexp_under_loss(dg = dg, F = F)(x))
#> }
#> <bytecode: 0x55b2ab604ab0>
#> <environment: 0x55b2b135b8a0>
#> 
```
