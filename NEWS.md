# alloscore2 0.0.0.9000

* Initial package setup: repository layout, GitHub Actions workflows for
  `R CMD check`, lint, format, test coverage and pkgdown, and the Air and lintr
  configuration.

* Ported the allocation and scoring machinery from the original
  [alloscore](https://github.com/aaronger/alloscore): `allocate()`,
  `alloscore()` and its methods, `post_process()`, the oracle functions, the gpl
  loss family, `add_pdqr_funs()`, `slim()`, the `stdize_*_params()` helpers and
  the `zxh_tab2` and `zxh_tab3` datasets.

## Bug fixes relative to the original package

* The `O`/`U` over/under-cost parameterization now works. `gpl_loss_fun()` and
  `exp_gpl_loss_fun()` previously errored on it and `dexp_gpl_loss()` silently
  returned `NULL`.

* A supplied `dg` is now honored instead of being silently discarded and
  recomputed from `g`.

* `exp_gpl_loss_fun()` now applies its `offset` argument, which was accepted and
  ignored.

* `new_gpl_df()` can infer `N` from its arguments; the code path referred to an
  undefined variable.

* `alloscore()` on a `slim` object now honors `against_oracle`, which was
  accepted and ignored.

* `allocate()` returns a well-formed `allocated` object when no target has any
  marginal benefit. It previously returned a data frame with no `xdf` column, no
  class and no attributes, which nothing downstream could consume.

* `allocate()` now fails with a clear message when `g` has an unbounded
  derivative at zero, as `g = "log(x)"` does. It previously emitted messages and
  returned its initial iterate unchanged. Use a shifted increment function such
  as `g = "log(1 + x)"`.

* Every dplyr and tidyr call is namespaced and declared. The original package
  only worked with the tidyverse attached.

* `weights.allocated()` and `alloscore.slim()` now match the signatures of their
  generics.

* Added `as_alloscore_df()`, `allocate_model_out()` and `alloscore_model_out()`,
  which take a hubverse `model_out_tbl` and `oracle_output` directly. Predictive
  quantiles are turned into cdfs and quantile functions with `distfromq`, so the
  conversion that callers used to hand-roll is no longer needed. Only the
  `quantile` output type is supported.

* Results agree with the original package to within root-finding tolerance; see
  `tests/testthat/test-legacy-equivalence.R`.

* Ported `plot_components()`, `plot_components_slim()`, `plot_scores_slim()` and
  `plot_iterations()`.

* `plot_components()` and `plot_scores_slim()` work. They previously called the
  nonexistent `tidyr::any_of()` and referred to an undefined variable
  respectively.

* `plot_iterations()` no longer calls `require()` at runtime; `patchwork` is a
  declared dependency. It also accepts a single row of `allocate_model_out()`
  output, not only an `allocated` object.

* Every ggplot2, forcats and scales call is namespaced and declared.
