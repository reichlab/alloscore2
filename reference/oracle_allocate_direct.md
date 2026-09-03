# Find the oracle allocation directly

A closed form for the oracle's allocation, avoiding the machinery of
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md). If
the observed outcomes are affordable the oracle allocates exactly those;
otherwise it scales them down proportionally. Assumes all targets share
the same gpl parameters and that `g` is the identity.

## Usage

``` r
oracle_allocate_direct(y, K, w)
```

## Arguments

- y:

  observed outcomes, one per target.

- K:

  vector of budgets. Cannot be supplied via `df`.

- w:

  numeric vector of costs per unit of resource allocated to each target.

## Value

A numeric vector of allocations.

## Examples

``` r
oracle_allocate_direct(y = c(3, 5), K = 4, w = 1)
#> [1] 1.5 2.5
oracle_allocate_direct(y = c(3, 5), K = 100, w = 1)
#> [1] 3 5
```
