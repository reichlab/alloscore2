# Build a p/d/q/r function with parameters fixed

Build a p/d/q/r function with parameters fixed

## Usage

``` r
pdqr_factory(..., dist, type, trans = NULL, trans_inv = NULL, transpars = NULL)
```

## Arguments

- ...:

  parameter name-value pairs to be fixed in the returned function.
  Parameters not accepted by the target distribution function are
  ignored, so entire rows of a forecast data frame may be passed in.

- dist:

  distribution root name, such as `"norm"` or `"beta"`, or `"distfromq"`
  to interpolate a distribution through predictive quantiles.

- type:

  one of `"p"`, `"d"`, `"q"` or `"r"`.

- trans:

  function of an outcome `x` and parameters, pre-composed with the `p`
  and `d` functions. Use this for distributions whose support must be
  rescaled, such as a beta distribution on `[x_min, x_max]`.

- trans_inv:

  inverse of `trans`, post-composed with the `q` and `r` functions.

- transpars:

  parameters for `trans` and `trans_inv` that are not columns of `df`.

## Value

A function of one argument: a cdf (`"p"`), density (`"d"`), quantile
function (`"q"`) or random generator (`"r"`).

## Examples

``` r
F <- pdqr_factory(mean = 5, sd = 2, dist = "norm", type = "p")
F(5)
#> [1] 0.5

# a distribution interpolated through predictive quantiles
Q <- pdqr_factory(
  ps = c(0.25, 0.5, 0.75), qs = c(4, 5, 6),
  dist = "distfromq", type = "q"
)
Q(0.5)
#> [1] 5
```
