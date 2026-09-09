# Derivative of the expected under-prediction loss

Derivative of the expected under-prediction loss

## Usage

``` r
dexp_under_loss(g = "x", dg = NULL, F)
```

## Arguments

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

- dg:

  derivative of `g`; if `NULL` or `NA` it is derived from `g`.

- F:

  predictive cdf of the outcome.

## Value

A function of an allocation `x`.

## Examples

``` r
dexp_under_loss(F = pnorm)(0)
#> [1] -0.5
```
