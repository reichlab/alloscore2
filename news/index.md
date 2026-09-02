# Changelog

## alloscore2 0.0.0.9000

- Initial package setup: repository layout, GitHub Actions workflows for
  `R CMD check`, lint, format, test coverage and pkgdown, and the Air
  and lintr configuration.

- Ported the allocation and scoring machinery from the original
  [alloscore](https://github.com/aaronger/alloscore):
  [`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md),
  [`alloscore()`](https://reichlab.github.io/alloscore2/reference/alloscore.md)
  and its methods,
  [`post_process()`](https://reichlab.github.io/alloscore2/reference/post_process.md),
  the oracle functions, the gpl loss family,
  [`add_pdqr_funs()`](https://reichlab.github.io/alloscore2/reference/add_pdqr_funs.md),
  [`slim()`](https://reichlab.github.io/alloscore2/reference/slim.md),
  the `stdize_*_params()` helpers and the `zxh_tab2` and `zxh_tab3`
  datasets.

### Bug fixes relative to the original package

- The `O`/`U` over/under-cost parameterization now works.
  [`gpl_loss_fun()`](https://reichlab.github.io/alloscore2/reference/gpl_loss_fun.md)
  and
  [`exp_gpl_loss_fun()`](https://reichlab.github.io/alloscore2/reference/exp_gpl_loss_fun.md)
  previously errored on it and
  [`dexp_gpl_loss()`](https://reichlab.github.io/alloscore2/reference/dexp_gpl_loss.md)
  silently returned `NULL`.

- A supplied `dg` is now honored instead of being silently discarded and
  recomputed from `g`.

- [`exp_gpl_loss_fun()`](https://reichlab.github.io/alloscore2/reference/exp_gpl_loss_fun.md)
  now applies its `offset` argument, which was accepted and ignored.

- [`new_gpl_df()`](https://reichlab.github.io/alloscore2/reference/new_gpl_df.md)
  can infer `N` from its arguments; the code path referred to an
  undefined variable.

- [`alloscore()`](https://reichlab.github.io/alloscore2/reference/alloscore.md)
  on a `slim` object now honors `against_oracle`, which was accepted and
  ignored.

- [`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md)
  returns a well-formed `allocated` object when no target has any
  marginal benefit. It previously returned a data frame with no `xdf`
  column, no class and no attributes, which nothing downstream could
  consume.

- [`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md)
  now fails with a clear message when `g` has an unbounded derivative at
  zero, as `g = "log(x)"` does. It previously emitted messages and
  returned its initial iterate unchanged. Use a shifted increment
  function such as `g = "log(1 + x)"`.

- Every dplyr and tidyr call is namespaced and declared. The original
  package only worked with the tidyverse attached.

- [`weights.allocated()`](https://reichlab.github.io/alloscore2/reference/weights.allocated.md)
  and
  [`alloscore.slim()`](https://reichlab.github.io/alloscore2/reference/alloscore.md)
  now match the signatures of their generics.

- Added
  [`as_alloscore_df()`](https://reichlab.github.io/alloscore2/reference/as_alloscore_df.md),
  [`allocate_model_out()`](https://reichlab.github.io/alloscore2/reference/allocate_model_out.md)
  and
  [`alloscore_model_out()`](https://reichlab.github.io/alloscore2/reference/alloscore_model_out.md),
  which take a hubverse `model_out_tbl` and `oracle_output` directly.
  Predictive quantiles are turned into cdfs and quantile functions with
  `distfromq`, so the conversion that callers used to hand-roll is no
  longer needed. Only the `quantile` output type is supported.

- Results agree with the original package to within root-finding
  tolerance; see `tests/testthat/test-legacy-equivalence.R`.
