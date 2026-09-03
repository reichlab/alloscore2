# Plot the components of a slim scored allocation

Plot the components of a slim scored allocation

## Usage

``` r
plot_components_slim(
  slim_df,
  Ks = NULL,
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = TRUE,
  show_raw = TRUE,
  order_at_K = NULL,
  order_at_model = NULL,
  order_at_origin_time = NULL,
  pal_top = c("#CD3333", "#009ACD", "#FFB90F", "#8B3E2F", "#8B8B00"),
  bar_positioning = c("stack", "dodge")
)
```

## Arguments

- slim_df:

  a slim scored allocation; see
  [`slim()`](https://reichlab.io/alloscore2/reference/slim.md).

- Ks:

  budgets to plot. Defaults to `NULL`, which keeps all of them; note
  that the bar layout requires a single budget.

- origin_time_col_name:

  name of the column holding an origin time, used to facet.

- model_col_name:

  name of the column holding a model name. For hubverse model output
  this is `"model_id"`.

- target_col_name:

  name of the column holding target names.

- show_oracle:

  whether to add the oracle's components as an extra model.

- show_raw:

  plot the forecaster's own losses rather than its losses relative to
  the oracle.

- order_at_K, order_at_model, order_at_origin_time:

  order the targets by their contribution at this budget, model or
  origin time. By default the targets are ordered over the whole data
  set.

- pal_top:

  colours for the largest contributors when an ordering slice is given;
  the remaining targets are shown in grey.

- bar_positioning:

  `"stack"` or `"dodge"`, for the single-budget layout.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

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
plot_components_slim(slim(scored))

```
