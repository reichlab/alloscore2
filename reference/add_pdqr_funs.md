# Add list columns of p/d/q/r functions to a forecast data frame

Given a data frame with one row per target, a `dist` column (or a `dist`
argument) naming a distribution, and columns for that distribution's
parameters, adds list columns holding the corresponding cdf, density,
quantile function and/or random generator.
[`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md)
needs only the cdf (`"p"`) and quantile function (`"q"`).

## Usage

``` r
add_pdqr_funs(
  df,
  dist = df$dist,
  trans = NULL,
  trans_inv = NULL,
  transpars = NULL,
  types = c("p", "d", "q", "r"),
  fnames = c(p = "F", d = "f", q = "Q", r = "r")
)
```

## Arguments

- df:

  data frame with one row per target. It must have a column for each
  parameter required by the distribution functions named in a `dist`
  column or in the `dist` argument.

- dist:

  character vector of length 1 or `nrow(df)` giving distribution root
  names (or `"distfromq"`); required if `df` has no `dist` column.

- trans:

  function of an outcome `x` and parameters, pre-composed with the `p`
  and `d` functions. Use this for distributions whose support must be
  rescaled, such as a beta distribution on `[x_min, x_max]`.

- trans_inv:

  inverse of `trans`, post-composed with the `q` and `r` functions.

- transpars:

  parameters for `trans` and `trans_inv` that are not columns of `df`.

- types:

  which of `"p"`, `"d"`, `"q"`, `"r"` to add.

- fnames:

  names to give the added list columns.

## Value

A tibble with the requested list columns added.

## Examples

``` r
fc <- add_pdqr_funs(
  tibble::tibble(
    target_names = c("a", "b"),
    dist = "norm",
    mean = c(5, 8),
    sd = c(1, 2)
  ),
  types = c("p", "q")
)
fc$F[[1]](5)
#> [1] 0.5
```
