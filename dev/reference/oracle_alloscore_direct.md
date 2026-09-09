# Find and score the oracle allocation directly

Find and score the oracle allocation directly

## Usage

``` r
oracle_alloscore_direct(y, K, w, gpl_fns)
```

## Arguments

- y:

  observed outcomes, one per target.

- K:

  vector of budgets. Cannot be supplied via `df`.

- w:

  numeric vector of costs per unit of resource allocated to each target.

- gpl_fns:

  list of gpl loss functions, one per target.

## Value

A tibble with columns `oracle` and `components_oracle`.

## Examples

``` r
oracle_alloscore_direct(
  y = c(3, 5), K = 4, w = 1,
  gpl_fns = list(gpl_loss_fun(alpha = 1), gpl_loss_fun(alpha = 1))
)
#> # A tibble: 2 × 2
#>   oracle components_oracle
#>    <dbl>             <dbl>
#> 1    1.5               1.5
#> 2    2.5               2.5
```
