# Create an expected gpl loss function

This is the per-target contribution to the objective minimized by
[`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md).

## Usage

``` r
exp_gpl_loss_fun(
  dg = function(u) 1,
  F,
  kappa = 1,
  alpha = NA,
  O = NA,
  U = NA,
  offset = 0
)
```

## Arguments

- dg:

  derivative of the increment function `g`.

- F:

  predictive cdf of the outcome.

- kappa:

  scale factor.

- alpha:

  normalized loss when the outcome `y` exceeds the allocation `x`.
  Exactly one of `alpha` and `U` must be supplied.

- O:

  cost incurred when the allocation `x` exceeds the outcome `y`; equals
  `kappa * (1 - alpha)`.

- U:

  cost incurred when the outcome `y` exceeds the allocation `x`; equals
  `kappa * alpha`.

- offset:

  a constant added to the expected loss. Unlike
  [`gpl_loss_fun()`](https://reichlab.github.io/alloscore2/reference/gpl_loss_fun.md),
  a function-valued `offset` is not supported here, since its
  expectation would itself require integration.

## Value

A function of an allocation `x` giving the expected loss with respect to
the distribution `F`.

## Examples

``` r
Z <- exp_gpl_loss_fun(F = pnorm, alpha = 0.5)
Z(0)
#> [1] 0.3989423
```
