# One-way ANOVA

`pharma_anova()` compares means across the observed levels of **one categorical group**. The model is \(Y_{ij}=\mu+\alpha_i+\varepsilon_{ij}\); the ordinary F test evaluates whether the group means are equal. A small p-value does not measure the size of the difference or identify which groups differ.

```r
library(PharmaStatsR)

fit <- pharma_anova(response ~ treatment, data = pharma_sample)
summary(fit)
```

## Numeric group codes

A numeric predictor is treated by `stats::aov()` as a quantitative covariate. For three or more doses, this tests a trend with one slope rather than the omnibus equality of group means. Encode group codes explicitly to request a categorical comparison:

```r
fit <- pharma_anova(
  response ~ factor(dose),
  data = pharma_sample
)
summary(fit)
```

The helper accepts a factor, character, or logical group and requires an intercept. It rejects interactions, multiple predictors, and missing response or group values. The original data are passed to `stats::aov()` so transformations in the formula remain available.

## Interpretation

The ordinary F test assumes independent errors and a common within-group variance, with normally distributed errors for its usual small-sample reference distribution. Inspect residuals and group sizes before interpreting the result. For unequal variances, consider `stats::oneway.test(..., var.equal = FALSE)` as a distinct Welch analysis; repeated observations or adjusted designs need a model that represents those features. See the [method guide](methods.md) and [limitations](limitations.md).
