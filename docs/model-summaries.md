# Model summaries in R

Use `summary(fit)` to inspect a model in the console and
`coef(summary(fit))` to extract its coefficient table when its model class
provides one. PharmaStatsR retains native model classes so their usual R
methods remain available. ANCOVA adds a summary method for its combined result.

## ANCOVA: the familiar lm display

```r
library(PharmaStatsR)
trial <- data.frame(
  response = c(11, 11, 13, 17, 14, 16, 20, 26),
  treatment = factor(rep(c("A", "B"), each = 4)),
  baseline = rep(0:3, 2)
)
fit <- pharma_ancova(response ~ treatment + baseline, trial)
s <- summary(fit)
s
coef(s)
s$sigma
s$r.squared
s$adj.r.squared
s$fstatistic
```

The first section uses the additive model's native
[`summary.lm()`](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/summary.lm.html):
stored call, residual distribution, estimates, standard errors, t tests,
residual standard error, R-squared, adjusted R-squared, and overall F test.
The coefficient table has the familiar `Estimate`, `Std. Error`, `t value`,
and `Pr(>|t|)` columns. Native coefficient-correlation behavior
is preserved. The summary is a structured result, not just printed text:

```r
s$slope_homogeneity
s$adjusted_means
print(summary(fit, correlation = TRUE), digits = 5, signif.stars = FALSE)
summary(fit$interaction_model) # inspect the separate interaction fit
```

The following sections show the stored treatment-by-covariate interaction F
comparison and treatment adjusted means at the original covariate mean.
The interaction test is a common-slope diagnostic; it differs from the
additive model's overall F test. A large interaction p-value does not establish
equal slopes. Confidence limits retain the level selected when fitting and
are individual intervals without multiplicity adjustment. Summary/printing
does not refit models or change the stored values.

Existing ANCOVA fits saved before these methods were introduced remain usable:

```r
path <- tempfile(fileext = ".rds")
saveRDS(fit, path)
restored <- readRDS(path)
summary(restored)
unlink(path)
```

Load PharmaStatsR in a fresh session before summarizing a restored result.
The fitted object still exposes `fit$model`, `fit$interaction_model`, and its
other list components. The new summary inherits from `summary.lm`, so its
standard coefficient extraction works without a new top-level function.

## Covariate mixed models

```r
d <- data.frame(SubjectID = rep(1:4, each = 3), Time = rep(c(-1, 0, 1), 4))
d$DV <- 2 + 1.5 * d$Time + rep(c(-3, -1, 1, 3), each = 3) +
  rep(c(1, -2, 1), 4)
mixed <- fit_covariate_model(d, "DV", "SubjectID", "Time")
summary(mixed)
coef(summary(mixed))
summary(mixed)$tTable
nlme::VarCorr(mixed)
```

The native [`nlme` summary](https://stat.ethz.ch/R-manual/R-patched/library/nlme/html/summary.lme.html)
supplies fixed-effect estimates, standard errors, denominator degrees of
freedom, t statistics and p-values. Its full display includes variance
components, residual and fit information. Name-repaired fits use backend
coefficient labels; `mixed$column_map` records their original names.
Ordinary-lm R-squared and an overall OLS F test are not added to mixed models.
Use [rendered reports](covariate-reports.md) for HTML/PDF output.

## Other result types

| Result | Console workflow | Interpretation |
| --- | --- | --- |
| `pharma_response_surface()` (`lm`) | `summary(fit)`, `coef(summary(fit))` | Ordinary linear-model inference |
| `pharma_logistic_regression()` (`glm`) | `summary(fit)`, `coef(summary(fit))` | Binomial model coefficients on the log-odds scale |
| `pharma_survival_fit()` (`coxph`) | `summary(fit)`, `coef(summary(fit))` | Cox model summary, with its own coefficient columns |
| `pharma_lmm()` (`lmerMod`) | `summary(fit)`, `coef(summary(fit))` | Native lme4 summary; fixed-effect p-values are not supplied by default |
| ANOVA (`aov`, `aovlist`) | `summary(fit)` | ANOVA tables, with separate strata where applicable |
| Tests returning `htest` | `print(result)` | Test statistic, p-value and other test-specific results |
| Covariate screeners returning names | Inspect the returned vector | Selected names are not a fitted-model summary |
| Imputed LASSO screening result | `result$cv`, `result$selected`, `result$fit` | Selection/CV output; ordinary unpenalized t tests are not supplied |

In particular, [lme4 documents its p-value choices](https://lme4.github.io/lme4/reference/pvalues.html);
PharmaStatsR does not silently choose an additional approximation. Model
families share the R workflow, not an identical set of inference statistics.
See each method's help and [evidence inventory](method-inventory.md).
