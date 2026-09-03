# Create marginal expected benefit functions for a `gpl_df`

The marginal expected benefit of allocating to target `i` is
\$\$\Lambda_i(x) = -\frac{1}{w_i}\frac{d}{dx} E L_i(x, Y_i) =
\frac{\kappa_i}{w_i} g'(x) (\alpha_i - F_i(x)),\$\$ a decreasing
function of `x`.
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md)
equalizes it across targets.

## Usage

``` r
meb_gpl_df(df, F, w)
```

## Arguments

- df:

  a `gpl_df`, as created by
  [`new_gpl_df()`](https://reichlab.io/alloscore2/reference/new_gpl_df.md).

- F:

  list of predictive cdfs, one per row of `df`.

- w:

  weights (costs per unit allocated) used in the budget constraint.

## Value

A list of functions of an allocation `x`, one per target.

## Examples

``` r
gdf <- new_gpl_df(N = 2, alpha = 0.5)
meb <- meb_gpl_df(gdf, F = list(pnorm, pnorm), w = 1)
meb[[1]](0)
#> [1] 0
```
