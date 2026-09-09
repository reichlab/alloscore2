# Basic g-linear loss for over-prediction of an outcome

Basic g-linear loss for over-prediction of an outcome

## Usage

``` r
over_loss(g = function(u) u)
```

## Arguments

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

## Value

A function of an allocation `x` and an outcome `y` that penalizes only
over-prediction.

## Examples

``` r
ol <- over_loss()
ol(x = 3, y = 1)
#> [1] 2
ol(x = 1, y = 3)
#> [1] 0
```
