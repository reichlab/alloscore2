## Data transcribed from Tables 2 and 3 of
##   B. Zhang, X. Xu, and Z. Hua, "A binary solution method for the
##   multiproduct newsboy problem with budget constraint,"
##   Int. J. Prod. Econ., vol. 117, no. 1, pp. 136-141, 2009.
##
## Columns
##   Product  product number
##   v        cost of revenue lost per unit not stocked
##   h        cost incurred per unit left over
##   c        cost per unit
##   mu, sigma           mean and sd of Normal demand           (Table 2)
##   x_min, x_max        support bounds of Beta demand          (Table 3)
##   Balpha, Bbeta       shape1 and shape2 of Beta demand       (Table 3)
##   q_zxh    the (v - c) / (h + v) demand quantile, as printed by ZXH
##   GIM      solution of Abdel-Malek and Montanari (2005a)
##   Opt      optimal solution reported by ZXH
##
## Table 2 uses a budget of K = 2500 and Table 3 a budget of K = 6500, in both
## cases with the unit cost `c` as the allocation weight.

zxh_tab2 <- data.frame(
  Product = as.character(1:17),
  v = c(
    7L,
    12L,
    30L,
    30L,
    40L,
    45L,
    16L,
    21L,
    42L,
    34L,
    20L,
    15L,
    10L,
    20L,
    47L,
    35L,
    22L
  ),
  h = c(1L, 2L, 4L, 4L, 2L, 5L, 1L, 2L, 3L, 5L, 3L, 5L, 3L, 3L, 2L, 4L, 1L),
  c = c(
    4L,
    8L,
    19L,
    17L,
    23L,
    15L,
    10L,
    10L,
    40L,
    20L,
    10L,
    7L,
    4L,
    12L,
    33L,
    21L,
    11L
  ),
  mu = c(
    102L,
    73L,
    123L,
    95L,
    62L,
    129L,
    69L,
    83L,
    120L,
    89L,
    115L,
    91L,
    52L,
    76L,
    66L,
    147L,
    104L
  ),
  sigma = c(
    51.0,
    18.3,
    30.8,
    23.8,
    15.5,
    43.0,
    34.5,
    41.5,
    30.0,
    22.3,
    38.3,
    30.3,
    17.3,
    38.0,
    16.5,
    36.8,
    34.7
  ),
  q_zxh = c(
    85.75,
    62.64,
    108.90,
    87.88,
    58.26,
    139.89,
    55.98,
    80.74,
    68.96,
    80.95,
    108.71,
    83.32,
    50.33,
    61.14,
    56.66,
    133.71,
    102.11
  ),
  GIM = c(
    0.00,
    0.00,
    0.00,
    0.00,
    0.00,
    106.86,
    0.00,
    14.02,
    0.00,
    0.00,
    15.58,
    42.20,
    34.56,
    0.00,
    0.00,
    0.00,
    15.23
  ),
  Opt = c(
    0.00,
    0.00,
    0.00,
    0.00,
    0.00,
    106.85,
    0.00,
    14.01,
    0.00,
    0.00,
    15.65,
    42.25,
    34.60,
    0.00,
    0.00,
    0.00,
    15.13
  ),
  stringsAsFactors = FALSE
)

zxh_tab3 <- data.frame(
  Product = as.character(1:6),
  v = c(7L, 12L, 30L, 17L, 27L, 10L),
  h = c(1L, 2L, 4L, 3L, 5L, 2L),
  c = c(4L, 7L, 15L, 10L, 15L, 6L),
  x_min = c(100L, 50L, 75L, 50L, 50L, 73L),
  x_max = c(300L, 250L, 150L, 200L, 200L, 275L),
  Balpha = c(2.0, 1.0, 1.0, 2.0, 2.0, 0.8),
  Bbeta = c(1.0, 1.2, 2.0, 2.0, 3.0, 0.2),
  q_zxh = c(222.47, 111.60, 93.93, 109.79, 97.26, 239.02),
  GIM = c(206.83, 95.69, 90.10, 100.12, 90.07, 209.35),
  Opt = c(207.93, 96.73, 90.34, 100.78, 90.55, 211.69),
  stringsAsFactors = FALSE
)

usethis::use_data(zxh_tab2, zxh_tab3, overwrite = TRUE)
