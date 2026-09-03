# Get the gpl loss data frame of an allocation

Get the gpl loss data frame of an allocation

## Usage

``` r
gpl(adf)
```

## Arguments

- adf:

  an object of class `allocated`, as returned by
  [`allocate()`](https://reichlab.io/alloscore2/reference/allocate.md).

## Value

The `gpl_df` stored in the `"gpl_df"` attribute of `adf`.

## Examples

``` r
fc <- add_pdqr_funs(
  tibble::tibble(target_names = c("a", "b"), dist = "norm", mean = c(5, 8), sd = 1),
  types = c("p", "q")
)
gpl(allocate(fc, K = 10))
#> # A tibble: 2 × 9
#>   g     dg    target_names kappa alpha O     U     offset gpl_loss_fun
#> * <chr> <lgl> <chr>        <dbl> <dbl> <lgl> <lgl>  <dbl> <list>      
#> 1 x     NA    a                1     1 NA    NA         0 <fn>        
#> 2 x     NA    b                1     1 NA    NA         0 <fn>        
```
