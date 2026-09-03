# Multiproduct newsboy data with Beta demand

Data transcribed from Table 3 of Zhang, Xu and Hua (2009), used there
with a budget of `K = 6500` and the unit cost `c` as the allocation
weight. The demand distributions are Beta distributions rescaled onto
`[x_min, x_max]`, so working with them requires the `trans` and
`trans_inv` arguments of
[`add_pdqr_funs()`](https://reichlab.io/alloscore2/reference/add_pdqr_funs.md).

## Usage

``` r
zxh_tab3
```

## Format

A data frame with 6 rows and 11 columns:

- Product:

  product number.

- v:

  cost of revenue lost per unit not stocked.

- h:

  cost incurred per unit left over.

- c:

  cost per unit.

- x_min:

  lower bound of the demand distribution's support.

- x_max:

  upper bound of the demand distribution's support.

- Balpha:

  the `shape1` parameter of the demand distribution.

- Bbeta:

  the `shape2` parameter of the demand distribution.

- q_zxh:

  the `(v - c) / (h + v)` quantile of the demand distribution, as given
  by Zhang, Xu and Hua.

- GIM:

  solution of Abdel-Malek and Montanari (2005a).

- Opt:

  optimal solution reported by Zhang, Xu and Hua.

## Source

B. Zhang, X. Xu, and Z. Hua, "A binary solution method for the
multiproduct newsboy problem with budget constraint," Int. J. Prod.
Econ., vol. 117, no. 1, pp. 136-141, 2009.

## See also

[zxh_tab2](https://reichlab.io/alloscore2/reference/zxh_tab2.md) for the
Normal-demand example.
