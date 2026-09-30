# Paired two-condition ANOVA

`pharma_repeated_anova()` fits a one-factor within-subject ANOVA for two observations per subject, one in each condition. It uses `stats::aov()` with `Error(subject)` to separate the variation between subjects from variation within subjects. Subject IDs and condition labels must be **factors**; numeric IDs in the error term can specify a different model.

```r
library(PharmaStatsR)

paired <- transform(pharma_repeated,
  subject = factor(subject), condition = factor(condition))
fit <- pharma_repeated_anova(response ~ condition + Error(subject), paired)
summary(fit)
```

The condition test appears in `summary(fit)[["Error: Within"]][[1L]]`. The result is an `aovlist`, with separate subject and within-subject error strata. In this two-condition design, the condition F statistic is the square of the paired t statistic.

## Numerical reference

For four subjects with responses A = (2, 4, 5, 7) and B = (3, 6, 6, 10), the paired differences B − A are (1, 2, 1, 3). Their mean is 1.75 and their centered sum of squares is 2.75. The condition sum of squares is 6.125, the within-subject residual sum of squares is 1.375, and the F statistic is (F_{1,3}=147/11\approx13.364), with (p\approx0.03535). [The regression test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-repeated-anova.R) checks these hand-derived values and an independent F-distribution tail.

## Input and interpretation

- Use exactly `response ~ condition + Error(subject)` with simple column names and an intercept. The response must be finite and numeric; subject and condition must be factors. Convert the bundled example data explicitly, as shown above.
- There must be exactly two observed conditions, at least three subjects, and exactly one record for each subject-condition pair. Missing model values, duplicate or incomplete pairs, and zero or non-finite paired-difference variance error. Prepare the population first; `subset`, `weights`, `na.action`, and `offset` are unsupported.
- The F test assumes subjects are independent and the within-subject differences have a suitable distribution. This helper does not handle covariates, more conditions, extra within-subject factors, unequal replication, or missing follow-up. For such designs, specify and assess a suitable model separately; a two-level complete-pair result does not validate a broader repeated-measures analysis.

Earlier calls that passed numeric subject IDs to `Error(subject)` may have produced a different error structure. Recode IDs and condition labels as factors and recompute those results. See [limitations](limitations.md) and the [method inventory](method-inventory.md) for review scope.
