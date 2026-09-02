# Convert over/under-prediction costs to `kappa` and `alpha`

Convert over/under-prediction costs to `kappa` and `alpha`

## Usage

``` r
stdize_ou_params(O, U)
```

## Arguments

- O:

  cost incurred when the allocation exceeds the outcome.

- U:

  cost incurred when the outcome exceeds the allocation.

## Value

A data frame with columns `kappa` and `alpha`.

## Examples

``` r
stdize_ou_params(O = 1, U = 3)
#>   kappa alpha
#> 1     4  0.75
```
