# Multiproduct newsboy data with Normal demand

Data transcribed from Table 2 of Zhang, Xu and Hua (2009), used there
with a budget of `K = 2500` and the unit cost `c` as the allocation
weight. The `Opt` column holds the published optimal solution, which
makes this dataset an external check on
[`allocate()`](https://reichlab.github.io/alloscore2/reference/allocate.md).

## Usage

``` r
zxh_tab2
```

## Format

A data frame with 17 rows and 9 columns:

- Product:

  product number.

- v:

  cost of revenue lost per unit not stocked.

- h:

  cost incurred per unit left over.

- c:

  cost per unit.

- mu:

  mean of demand.

- sigma:

  standard deviation of demand.

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

[zxh_tab3](https://reichlab.github.io/alloscore2/reference/zxh_tab3.md)
for the Beta-demand example.
