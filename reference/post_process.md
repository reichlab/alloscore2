# Repair allocations left infeasible by plateaus in the objective

The objective has flat stretches wherever a predictive distribution has
a point mass – always, for the degenerate distributions used by
[`oracle_allocate()`](https://reichlab.github.io/alloscore2/reference/oracle_allocate.md)
– so bisection on lambda can stall at an allocation that does not
exhaust the budget. This finds bracketing vectors `x_L` and `x_U` and
interpolates between them to hit the budget exactly.

## Usage

``` r
post_process(x, K, lam, w, Lambda, eps_lam, point_mass_window)
```

## Arguments

- x:

  final allocation from the lambda search.

- K:

  budget.

- lam:

  final lambda iterate.

- w:

  weights.

- Lambda:

  list of marginal expected benefit functions.

- eps_lam:

  relative tolerance for terminating the bisection on lambda.

- point_mass_window:

  distance by which search intervals are widened in order to catch point
  masses in the `F`s, intended or otherwise.

## Value

An allocation vector exhausting the budget.

## Examples

``` r
# a pair of targets whose marginal benefit declines linearly
Lambda <- list(function(x) 1 - x / 10, function(x) 1 - x / 10)
# the allocation c(8, 8) costs 16, over a budget of 12
post_process(
  x = c(8, 8), K = 12, lam = 0.5, w = c(1, 1),
  Lambda = Lambda, eps_lam = 1e-4, point_mass_window = 1e-3
)
#> [1] 6 6
```
