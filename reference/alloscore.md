# Score allocations against realized outcomes

Allocates a budget under a set of forecasts and then scores the realized
gpl loss of that allocation, optionally relative to the loss of an
oracle that knew the outcomes in advance. The oracle-relative score is
non-negative and is zero for a perfect forecast.

## Usage

``` r
alloscore(df = NULL, ...)

# Default S3 method
alloscore(
  df = NULL,
  K,
  target_names = NA,
  y,
  F = NULL,
  Q = NULL,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  dg = NA,
  eps_K = 0.01,
  eps_lam = 1e-04,
  against_oracle = TRUE,
  slim = FALSE,
  ...
)

# S3 method for class 'allocated'
alloscore(df, y, against_oracle = TRUE, ...)

# S3 method for class 'slim'
alloscore(df, ys, against_oracle = TRUE, ...)
```

## Arguments

- df:

  a data frame of forecasts, an `allocated` object (as returned by
  [`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md)),
  or a `slim` object (as returned by
  [`slim()`](https://reichlab.github.io/alloscore2/reference/slim.md)).
  The method dispatched on determines which further arguments apply.

- ...:

  arguments passed to methods.

- K:

  vector of budgets. Cannot be supplied via `df`.

- target_names:

  names for the allocation targets, or the name of a column of `df`
  holding them. Defaults to the row indices.

- y:

  numeric vector of observed outcomes, one per target.

- F:

  list of predictive cdfs, one per target.

- Q:

  list of predictive quantile functions, one per target.

- w:

  numeric vector of costs per unit of resource allocated to each target.

- kappa:

  scale factor.

- alpha:

  normalized loss when the outcome `y` exceeds the allocation `x`.
  Exactly one of `alpha` and `U` must be supplied.

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

- dg:

  derivative of the increment function `g`. If `NA`, `g` is
  differentiated symbolically with
  [`stats::D()`](https://rdrr.io/r/stats/deriv.html).

- eps_K:

  relative tolerance on the budget, below which no post-processing is
  attempted.

- eps_lam:

  relative tolerance for terminating the bisection on lambda.

- against_oracle:

  logical; if `TRUE`, components and scores relative to the oracle
  allocation are included.

- slim:

  logical; if `TRUE`, drop the heavy list columns before scoring. See
  [`slim()`](https://reichlab.github.io/alloscore2/reference/slim.md).

- ys:

  a list of named outcome vectors, whose names must match the target
  names of `df`.

## Value

A tibble of the form returned by
[`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md),
with the class `scored` prepended and additional columns

- components_raw:

  the realized gpl loss at each target (inside `xdf`).

- score_raw:

  the sum of `components_raw`.

- components_oracle:

  the oracle's loss at each target (inside `xdf`).

- score_oracle:

  the sum of `components_oracle`.

- components:

  `components_raw - components_oracle` (inside `xdf`).

- score:

  `score_raw - score_oracle`.

- ytot:

  the total weighted outcome, `sum(w * y)`.

## Methods (by class)

- `alloscore(default)`: Allocates and then scores, for forecasts
  supplied as a data frame or as individual arguments.

- `alloscore(allocated)`: Scores an allocation that has already been
  computed.

- `alloscore(slim)`: Scores a slim allocation against many outcome
  vectors, for Monte Carlo work. Uses
  [`oracle_alloscore_direct()`](https://reichlab.github.io/alloscore2/reference/oracle_alloscore_direct.md)
  rather than a full oracle allocation.

## Examples

``` r
fc <- add_pdqr_funs(
  tibble::tibble(
    target_names = c("a", "b", "c"),
    dist = "norm",
    mean = c(5, 8, 12),
    sd = c(1, 2, 3)
  ),
  types = c("p", "q")
)
s <- alloscore(fc, y = c(4, 9, 11), K = c(10, 20))
s[, c("K", "score", "score_raw", "score_oracle")]
#> # A tibble: 2 × 4
#>       K  score score_raw score_oracle
#>   <dbl>  <dbl>     <dbl>        <dbl>
#> 1    10 0.0154     14.0         14   
#> 2    20 0.167       4.17         4.00
```
