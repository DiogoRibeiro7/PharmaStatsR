# Correlated outcomes with GEE

`pharma_gee()` fits a generalized estimating equation model through [`geepack::geeglm()`](https://stat.ethz.ch/CRAN/web/packages/geepack/refman/geepack.html). The result describes a population-averaged mean relationship under the supplied response family and working correlation. Its standard errors and interpretation require independent clusters and a suitable analysis plan.

```r
library(PharmaStatsR)

trial <- pharma_repeated[order(pharma_repeated$subject), ]
fit <- pharma_gee(
  response ~ condition,
  id = subject,
  data = trial,
  corstr = "exchangeable"
)
summary(fit)
```

A bare `id` name is looked up in `data`; an aligned vector such as `trial$subject` also works. Each cluster must occupy **consecutive rows**. The wrapper rejects an ID that is missing, has the wrong length, or reappears after another cluster. Check the visit order within each cluster when using an order-sensitive correlation structure such as `"ar1"`.

All model variables and cluster IDs must be complete. Decide how to address missing observations before calling the function; complete-case filtering may change the estimand or induce bias. The helper does not select a working correlation, handle informative missingness, or establish that records from different clusters are independent. Compare important results with a direct `geepack::geeglm()` fit and review the [general limitations](limitations.md).

## Fixed Gaussian independence reference

A small check uses four independent subjects with one observation at each
`condition` value, 0 and 1. Their responses by subject are (3, 6), (1, 5),
(2, 4), and (2, 5). Under a Gaussian identity-link mean model and
`corstr = "independence"`, the marginal fitted means are 2 and 5, giving an
intercept of 2 and a condition coefficient of 3. All eight rows are used; each
subject's two visits must be adjacent.

The two-column design matrix has `X'X = [[8, 4], [4, 4]]`. Using the residuals
from those fitted means, the four subject score vectors `X_i'(y_i - X_i beta)`
are `(2, 1)`, `(-1, 0)`, `(-1, -1)`, and `(0, 0)`. Summing their outer
products gives the meat matrix `[[6, 3], [3, 2]]`. Multiplying on both sides
by `(X'X)^-1` gives the uncorrected robust sandwich covariance
`[[1/8, -1/16], [-1/16, 1/8]]`, so each coefficient has a robust standard
error of `sqrt(1/8)`, approximately 0.354. The
[reference test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-gee-reference.R)
checks these fixed targets without using `geeglm()` to produce the expected
values. The separate [contract tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-gee.R)
cover interleaved or incomplete IDs, missing model values, the optional
backend, and a direct backend comparison.

The coefficient describes a population-averaged condition difference for
this identity-link model, conditional on the stated design. Independence
between subjects is required for the cluster sandwich interpretation.
Changing the working correlation can change estimating weights and
finite-sample uncertainty. Four subjects make the arithmetic transparent;
the resulting standard errors are illustrative and are not adequate
evidence for study-level inference.

## R help

Full arguments and return values: [`pharma_gee()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_gee.Rd). In an installed package, run `help("pharma_gee", package = "PharmaStatsR")`.
