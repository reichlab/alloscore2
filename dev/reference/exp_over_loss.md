# Expected g-linear loss for over-prediction of a random outcome

Expected g-linear loss for over-prediction of a random outcome

## Usage

``` r
exp_over_loss(dg = function(y) 1, F)
```

## Arguments

- dg:

  derivative of the increment function `g`.

- F:

  predictive cdf of the outcome.

## Value

A function of an allocation `x` giving the expected g-linear loss of
over-predicting an outcome distributed according to `F`.

## Examples

``` r
eol <- exp_over_loss(F = pnorm)
eol(0)
#> [1] 0.3989423
```
