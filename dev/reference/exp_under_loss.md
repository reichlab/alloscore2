# Expected g-linear loss for under-prediction of a random outcome

Expected g-linear loss for under-prediction of a random outcome

## Usage

``` r
exp_under_loss(dg = function(y) 1, F)
```

## Arguments

- dg:

  derivative of the increment function `g`.

- F:

  predictive cdf of the outcome.

## Value

A function of an allocation `x` giving the expected g-linear loss of
under-predicting an outcome distributed according to `F`.

## Examples

``` r
eul <- exp_under_loss(F = pnorm)
eul(0)
#> [1] 0.3989423
```
