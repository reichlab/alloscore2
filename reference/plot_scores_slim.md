# Plot allocation scores against the budget or over time

Plot allocation scores against the budget or over time

## Usage

``` r
plot_scores_slim(
  slim_df,
  Ks = NULL,
  ts = FALSE,
  ts_dates = NULL,
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = FALSE,
  show_raw = FALSE,
  order_at_K = NULL,
  order_at_model = NULL,
  order_at_origin_time = NULL,
  palette = NULL,
  linetypes = NULL,
  ytot = TRUE
)
```

## Arguments

- slim_df:

  a slim scored allocation; see
  [`slim()`](https://reichlab.github.io/alloscore2/reference/slim.md).

- Ks:

  budgets to plot. Defaults to `NULL`, which keeps all of them; note
  that the bar layout requires a single budget.

- ts:

  plot the score as a time series over `origin_time` rather than against
  the budget. Requires one budget per origin time, given in `Ks`.

- ts_dates:

  restrict a time series plot to these origin times.

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

- palette:

  colours for the models, passed to
  [`ggplot2::scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

- linetypes:

  line types for the models, passed to
  [`ggplot2::scale_linetype_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

- ytot:

  add a dashed vertical line at the total weighted outcome, the budget
  beyond which the oracle incurs no loss.

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
scored <- alloscore(fc, y = c(4, 9, 11), K = seq(5, 40, by = 5))
plot_scores_slim(slim(scored))

```
