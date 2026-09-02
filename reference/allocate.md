# Allocate a budget to minimize expected gpl loss

Solves \$\$\min_x \sum_i E\_{Y_i \sim F_i} L_i(x_i, Y_i)
\quad\text{subject to}\quad \sum_i w_i x_i \le K,\\ x_i \ge 0,\$\$ where
each \\L_i\\ is a generalized piecewise linear loss (see
[`gpl_loss_fun()`](https://reichlab.github.io/alloscore2/reference/gpl_loss_fun.md)).
The problem is separable and convex, so at the optimum the marginal
expected benefit \\\Lambda_i\\ (see
[`meb_gpl_df()`](https://reichlab.github.io/alloscore2/reference/meb_gpl_df.md))
is equal across all targets receiving a positive allocation.
`allocate()` bisects on that common value \\\lambda\\, inverting
\\\Lambda_i\\ for each target at each step. All values of `K` are solved
simultaneously, sharing root-finding work wherever they currently agree
on \\\lambda\\.

## Usage

``` r
allocate(
  df = NULL,
  K,
  target_names = NA,
  F = NULL,
  Q = NULL,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  dg = NA,
  eps_lam = 1e-04,
  eps_K = 0.01,
  point_mass_window = 0.001
)
```

## Arguments

- df:

  data frame with one row per target. Columns of `df` supply the other
  arguments: an argument left empty is filled from a like-named column,
  and an argument whose value is a length-1 string naming a column of
  `df` is replaced by that column, so `w = "c"` uses the `c` column as
  weights.

- K:

  vector of budgets. Cannot be supplied via `df`.

- target_names:

  names for the allocation targets, or the name of a column of `df`
  holding them. Defaults to the row indices.

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

- eps_lam:

  relative tolerance for terminating the bisection on lambda.

- eps_K:

  relative tolerance on the budget, below which no post-processing is
  attempted.

- point_mass_window:

  distance by which search intervals are widened in order to catch point
  masses in the `F`s, intended or otherwise.

## Value

A tibble of class `allocated`, with one row per value of `K` and columns

- K:

  the budget.

- x:

  list of named allocation vectors.

- xs:

  list of data frames holding the allocation at each iteration.

- qs_OK:

  whether the unconstrained (quantile) solution already satisfied the
  budget.

- lam, lamL, lamU:

  final Lagrange multiplier and its bracketing interval, with `*_seq`
  columns holding the full iteration history.

- post_processed:

  whether plateau post-processing was applied.

- xdf:

  list of per-target tibbles holding the allocation and a scoring
  function.

The `gpl_df`, `w` and `target_col_name` attributes carry the loss
functions, weights and target column name.

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
a <- allocate(fc, K = c(10, 20), alpha = 0.9)
a$xdf[[1]]
#> # A tibble: 3 × 3
#>   target_names     x score_fun
#>   <chr>        <dbl> <list>   
#> 1 a             2.50 <fn>     
#> 2 b             3.00 <fn>     
#> 3 c             4.50 <fn>     
```
