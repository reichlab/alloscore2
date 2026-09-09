# Plot the per-target components of an allocation score

Shows how a score decomposes across targets: as stacked or dodged bars
when a single budget is plotted, and as stacked areas over the budget
otherwise.

## Usage

``` r
plot_components(...)

# Default S3 method
plot_components(
  df,
  Ks = NULL,
  scored_col_name = "scored",
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = TRUE,
  ...
)

# S3 method for class 'allocated'
plot_components(
  ...,
  Ks = NULL,
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = TRUE
)
```

## Arguments

- ...:

  objects to plot. For the default method, a data frame with a list
  column of scored allocations; for the `allocated` method, one or more
  scored `allocated` objects.

- df:

  a data frame with a list column of scored allocations.

- Ks:

  budgets to plot. Defaults to `NULL`, which keeps all of them; note
  that the bar layout requires a single budget.

- scored_col_name:

  name of the list column holding the scored allocations.

- origin_time_col_name:

  name of the column holding an origin time, used to facet.

- model_col_name:

  name of the column holding a model name. For hubverse model output
  this is `"model_id"`.

- target_col_name:

  name of the column holding target names.

- show_oracle:

  whether to add the oracle's components as an extra model.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Methods (by class)

- `plot_components(default)`: Plots a data frame holding a list column
  of scored allocations, such as one row per model and origin time.

- `plot_components(allocated)`: Plots one or more scored `allocated`
  objects.

## Examples

``` r
fc <- add_pdqr_funs(
  tibble::tibble(
    target_names = c("a", "b", "c"), dist = "norm",
    mean = c(5, 8, 12), sd = c(1, 2, 3)
  ),
  types = c("p", "q")
)
scored <- alloscore(fc, y = c(4, 9, 11), K = c(10, 20, 30))
plot_components(scored)

```
