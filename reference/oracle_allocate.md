# Allocate as an oracle that knows the observed outcomes

Runs
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md)
with degenerate predictive distributions that place all of their
probability on the observed outcomes, giving the allocation against
which a forecaster's allocation is scored. Because those distributions
are point masses, the objective is piecewise constant and
[`post_process()`](https://reichlab.io/alloscore2/reference/post_process.md)
is always needed.

## Usage

``` r
oracle_allocate(gpl_df, y, K, w = 1, ...)
```

## Arguments

- gpl_df:

  a `gpl_df` (see
  [`new_gpl_df()`](https://reichlab.io/alloscore2/reference/new_gpl_df.md))
  or an `allocated` object, from which the loss parameters and weights
  are taken.

- y:

  observed outcomes, one per target.

- K:

  vector of budgets. Cannot be supplied via `df`.

- w:

  numeric vector of costs per unit of resource allocated to each target.

- ...:

  further arguments passed to
  [`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md).

## Value

An `allocated` tibble; see
[`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md).

## Examples

``` r
fc <- add_pdqr_funs(
  tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
  types = c("p", "q")
)
a <- allocate(fc, K = 10)
oracle_allocate(a, y = c(4, 9), K = 10)$x
#> [[1]]
#>        a        b 
#> 3.076911 6.923089 
#> 
```
