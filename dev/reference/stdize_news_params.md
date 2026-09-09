# Convert newsvendor parameters to `kappa` and `alpha`

Convert newsvendor parameters to `kappa` and `alpha`

## Usage

``` r
stdize_news_params(ax, ay = NULL, a_minus, a_plus)
```

## Arguments

- ax:

  wholesale cost per unit stocked.

- ay:

  unused; retained for symmetry with the source parameterization.

- a_minus:

  cost of revenue lost per unit of unmet demand.

- a_plus:

  cost incurred per unit left over.

## Value

A data frame with columns `kappa` and `alpha`, suitable for use inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Examples

``` r
stdize_news_params(ax = 4, a_minus = 7, a_plus = 1)
#>   kappa alpha
#> 1     8 0.375
```
