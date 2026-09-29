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
