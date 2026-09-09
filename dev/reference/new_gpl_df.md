# Create a data frame of gpl loss functions and their parameters

Recycles scalar arguments to length `N` and builds one gpl loss function
per target.

## Usage

``` r
new_gpl_df(
  N = NULL,
  target_names = NA,
  g = "x",
  dg = NA,
  kappa = 1,
  alpha = 1,
  O = NA,
  U = NA,
  offset = 0
)
```

## Arguments

- N:

  number of targets. If `NULL`, inferred from the longest argument.

- target_names:

  names of the targets, one per row.

- g:

  a non-decreasing increment function, supplied either as a function or
  as a string in the variable `x` such as `"log(x)"`.

- dg:

  derivative of `g`. Defaults to `NA`, in which case it is derived
  symbolically from `g` when needed.

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

A tibble of class `gpl_df` with one row per target, columns for each
loss parameter, and a `gpl_loss_fun` list column of loss functions.

## Examples

``` r
new_gpl_df(N = 3, alpha = c(0.5, 0.7, 0.9), target_names = c("a", "b", "c"))
#> # A tibble: 3 × 9
#>   g     dg    target_names kappa alpha O     U     offset gpl_loss_fun
#> * <chr> <lgl> <chr>        <dbl> <dbl> <lgl> <lgl>  <dbl> <list>      
#> 1 x     NA    a                1   0.5 NA    NA         0 <fn>        
#> 2 x     NA    b                1   0.7 NA    NA         0 <fn>        
#> 3 x     NA    c                1   0.9 NA    NA         0 <fn>        
```
