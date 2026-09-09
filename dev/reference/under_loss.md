# Basic g-linear loss for under-prediction of an outcome

Basic g-linear loss for under-prediction of an outcome

## Usage

``` r
under_loss(g = function(u) u)
```

## Arguments

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

## Value

A function of an allocation `x` and an outcome `y` that penalizes only
under-prediction.

## Examples

``` r
ul <- under_loss()
ul(x = 1, y = 3)
#> [1] 2
ul(x = 3, y = 1)
#> [1] 0
```
