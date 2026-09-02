# Create a generalized piecewise linear (gpl) loss function

The gpl loss of an allocation `x` against an outcome `y` is \$\$L(x, y)
= \kappa\[(1 - \alpha)(g(x) - g(y))\_+ + \alpha (g(y) - g(x))\_+\] +
\mathrm{offset}(y).\$\$ With `g(x) = x` this is the pinball (quantile)
loss at level `alpha`, scaled by `kappa`. Despite the name it need not
be piecewise linear, since `g` may be any non-decreasing increment
function.

## Usage

``` r
gpl_loss_fun(g = "x", kappa = 1, alpha = NA, O = NA, U = NA, offset = 0)
```

## Arguments

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

- kappa:

  scale factor.

- alpha:

  normalized loss when the outcome `y` exceeds the allocation `x`.
  Exactly one of `alpha` and `U` must be supplied.

- O:

  cost incurred when the allocation `x` exceeds the outcome `y`; equals
  `kappa * (1 - alpha)`.

- U:

  cost incurred when the outcome `y` exceeds the allocation `x`; equals
  `kappa * alpha`.

- offset:

  a constant, or a function of `y`, added to the loss. The default of
  `0` gives a loss with `L(x, x) = 0`.

## Value

A function of an allocation `x` and an outcome `y` giving the loss.

## Examples

``` r
# pinball loss at the median
L <- gpl_loss_fun(alpha = 0.5)
L(x = 1, y = 3)
#> [1] 1

# the equivalent over/under-cost parameterization
L2 <- gpl_loss_fun(O = 0.5, U = 0.5)
L2(x = 1, y = 3)
#> [1] 1
```
