# Get the weights of an allocated data frame

Get the weights of an allocated data frame

## Usage

``` r
# S3 method for class 'allocated'
weights(object, ...)
```

## Arguments

- object:

  an `allocated` object, as returned by
  [`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md).

- ...:

  ignored.

## Value

The named vector of weights used in the allocation.

## Examples

``` r
fc <- add_pdqr_funs(
  tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
  types = c("p", "q")
)
weights(allocate(fc, K = 10))
#> a b 
#> 1 1 
```
