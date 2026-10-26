# Model summaries in R

Use `summary(fit)` to inspect a model in the console and
`coef(summary(fit))` to extract its coefficient table when its model class
provides one. PharmaStatsR retains native model classes so their usual R
methods remain available. ANCOVA and imputed LASSO screening add summary methods
for their combined results.

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

For [weighted or subsetted ANCOVA](ancova.md#weights-and-row-selection),
the summary describes the selected rows and fitted precision weights.
The adjusted means use those rows' unweighted covariate mean.

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

## Imputed LASSO and elastic net

```r
block <- data.frame(
  x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
  y = c(-2, -2, 2, 2, 0, 0)
)
training <- block[rep(seq_len(6), 3), ]
fit <- screen_covariates_lasso_imputed(
  training, "y", c("x1", "x2"), lambda = c(2, 1, 0.5),
  foldid = rep(1:3, each = 6)
)
s <- summary(fit)
s
coef(s)
s$cv
```

The printed summary shows the retained/excluded row counts, number of folds,
imputation and encoding settings, mixing parameter, selected penalty, coefficient
table, selected raw candidates, and minimum held-out MSE. For this example,
there are 18 retained rows and three folds. The selected penalty is `0.5`,
minimum MSE is `1/4`, and coefficients are `(0, 2 - sqrt(3/8), 0)`.
The full MSE curve is `(8/3, 1, 1/4)` at penalties `(2, 1, 0.5)`, from the
[independent soft-threshold reference](lasso-imputation.md#independent-numerical-references).

`coef(s)` is a one-column `Estimate` matrix, including the intercept and zero
coefficients. It uses the selected column of the saved final model path without
interpolation. These estimates come from all retained development rows; the
stored CV errors come from held-out rows with preprocessing fitted inside each
training fold. MSE gives every retained row equal weight, even when folds have
different sizes. Counts describe rows, not subjects. The minimum is tuning error;
use an independent test set or outer resampling to assess future performance.

The same interface supports mean, median and kNN imputation, categorical
encoding, and all supported `alpha` settings. With encoding, coefficient labels
refer to design columns; `s$selected` retains raw candidate names, while
`s$selected_columns` identifies nonzero design columns. This is column-wise
penalization, not a grouped test. The first coefficient row is the intercept;
literal predictor labels are preserved even if a predictor is also named
`(Intercept)`.

The summary provides penalized estimates and tuning information. It does not
inherit from `summary.lm` or add OLS standard errors, t tests, p-values, or
post-selection inference. `print(s, digits = 6)` changes displayed precision
only and returns `s` invisibly. Neither summary nor printing refits preprocessing
or models, changes predictions, or draws random numbers.

New results have class `c("pharma_lasso_imputed", "list")` and keep their existing
list entries. `predict_lasso_imputed()` works as before. For a plain-list result
saved by an older version, enable summary dispatch explicitly after loading
PharmaStatsR:

```r
# older <- readRDS("saved-screening-result.rds")
# class(older) <- c("pharma_lasso_imputed", "list")
# summary(older)
```

This adds a class without refitting. The saved model, CV curve, fold labels,
mixing parameter and selection metadata must still be present and consistent;
incomplete saved results fail with a diagnostic. Existing plain lists continue
to work with the prediction helper without this class assignment. New results
and their summaries can be saved directly with `saveRDS()`.

The [summary tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-lasso-summary.R)
check the analytic coefficient/MSE targets, unequal-fold errors and ties,
encoded contrasts, saved results, literal labels, unchanged predictions and
printing. See the [summary help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/summary.pharma_lasso_imputed.Rd)
for structured fields.

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
| Imputed LASSO screening result | `summary(fit)`, `coef(summary(fit))`, `summary(fit)$cv` | Penalized estimates and tuning error; ordinary unpenalized t tests are not supplied |

In particular, [lme4 documents its p-value choices](https://lme4.github.io/lme4/reference/pvalues.html);
PharmaStatsR does not silently choose an additional approximation. Model
families share the R workflow, not an identical set of inference statistics.
See each method's help and [evidence inventory](method-inventory.md).
