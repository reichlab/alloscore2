# Convert meteorologist parameters to `kappa` and `alpha`

Convert meteorologist parameters to `kappa` and `alpha`

## Usage

``` r
stdize_met_params(C, L)
```

## Arguments

- C:

  marginal cost per unit of recommended protection.

- L:

  marginal loss due to under-provision of needed resources.

## Value

A data frame with columns `kappa` and `alpha`.

## Examples

``` r
stdize_met_params(C = 2, L = 10)
#>   kappa alpha
#> 1    10   0.8
```
