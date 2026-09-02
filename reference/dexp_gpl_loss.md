# Derivative of the expected gpl loss

For the linear increment function this is \$\$\kappa\\ g'(x)\\ (F(x) -
\alpha),\$\$ the quantity whose root gives the unconstrained optimal
allocation.

## Usage

``` r
dexp_gpl_loss(g = "x", dg = NULL, F, kappa = 1, alpha = NA, O = NA, U = NA)
```

## Arguments

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

- dg:

  derivative of `g`; if `NULL` or `NA` it is derived from `g`.

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

## Value

A function of an allocation `x` giving the derivative of the expected
loss with respect to the distribution `F`.

## Examples

``` r
# zero at the median of the predictive distribution
dexp_gpl_loss(F = pnorm, alpha = 0.5)(0)
#> [1] 0
```
