# ANCOVA with one continuous covariate

`pharma_ancova()` fits an additive linear model with exactly one
categorical treatment and one numeric covariate. It also fits the corresponding
treatment-by-covariate interaction model as a common-slope diagnostic and
reports treatment adjusted means at the unweighted covariate mean of the
selected observations.

```r
trial_data <- data.frame(
  response = c(11, 11, 13, 17, 14, 16, 20, 26),
  treatment = factor(rep(c("A", "B"), each = 4)),
  baseline = rep(0:3, 2)
)
result <- pharma_ancova(response ~ treatment + baseline, data = trial_data)
summary(result)
coef(summary(result))
result$slope_homogeneity
result$adjusted_means
```

The input formula must be additive and contain direct column names only. The
helper rejects extra predictors, interactions, missing/nonfinite model values,
a treatment with fewer than two observed levels, and a constant covariate.

## Weights and row selection

```r
trial_data$precision <- seq_len(nrow(trial_data))
weighted <- pharma_ancova(
  response ~ treatment + baseline, trial_data,
  weights = precision, subset = baseline > 0
)
summary(weighted)
weighted$covariate_mean # 2: arithmetic mean of the selected baseline values
rownames(weighted$model$model)
weighted$model$weights
```

Weights and subsets follow [R's model-frame lookup rules](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/model.frame.html):
columns in `data` are searched before the formula's environment. Expressions
and external vectors are supported. The function evaluates each option once
and uses the same selected values in the additive and interaction fits. Row order follows
the subset; inspect the stored model frames to see which observations were used.
Unused treatment levels disappear after selection. Logical treatments remain
logical when constructing adjusted predictions.

The selected weights must be finite, numeric and strictly positive. `NULL`
uses ordinary least squares. To exclude zero-weight rows, select them out
explicitly, for example `subset = precision > 0`. Missing or nonfinite weights
on selected rows are errors. Missing or nonfinite selected model values are
also errors, even with `na.action = na.omit`; explicitly filter incomplete
rows first. Missing values outside the subset are allowed. A subset that
produces missing rows, or removes all but one treatment level, is rejected.

These are relative precision weights: the model assumes error variance
proportional to `1 / weights`. They are not frequency counts or survey-design
weights. Standard errors, individual confidence limits and the nested-model F
comparison follow [weighted least squares in lm](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/lm.html).
The adjustment point remains the selected observations' unweighted arithmetic
covariate mean; precision weighting does not redefine that target. Confidence
intervals are for model means, not future observations. A common positive
rescaling of weights preserves coefficients, standard errors, adjusted-mean
intervals and the interaction test up to numerical tolerance.

Supported controls include `contrasts`, `tol`, `singular.ok`, `x`, and `y`.
The stored model frame and QR decomposition are required (`model = TRUE`,
`qr = TRUE`); `method` must be `"qr"` and `tol` must lie strictly between
zero and one. Both model designs require full column rank and positive residual
degrees of freedom. Standard `na.action` choices are accepted for compatibility
but do not override the complete-selected-row rule. Custom omission callbacks,
unknown/unnamed/duplicate options and offsets are rejected. For an offset model,
fit with `stats::lm()` directly and specify the offset for adjusted predictions.

### Migration

Refit analyses that failed with `..1 used in an incorrect context` when passing
weights. For subsets, adjusted means now use the selected rows and treatment
levels, rather than the full input frame. Review that change of adjustment
point when comparing old and new results. Unweighted fits without a subset
retain the existing numerical reference. Saturated or rank-deficient designs
now fail early; simplify the design or obtain sufficient observations rather
than interpreting undefined interaction tests. Existing saved fitted objects
and their summaries remain readable.

## Summary and returned components

`summary(result)` displays the additive model in the familiar `lm` format:
coefficient estimates, standard errors, t statistics and p-values; residuals,
residual standard error, R-squared, adjusted R-squared and the overall F test.
It then prints the stored interaction comparison and adjusted means. The
[summary guide](model-summaries.md) covers extraction, correlation/printing
options and saved fits. Standard `summary(result$model)` and
`summary(result$interaction_model)` remain available for the separate models.

The fitted result remains a list with class `pharma_ancova`:

- `model`: the additive ANCOVA `lm` fit.
- `interaction_model`: the treatment-by-covariate `lm` fit.
- `slope_homogeneity`: the nested-model partial F comparison.
- `adjusted_means`: treatment predictions at the selected rows' unweighted
  covariate mean, with individual model-based confidence intervals.
- `covariate_mean`: the value used for adjustment.
- `treatment` and `covariate`: detected column names.

A large interaction p-value does not prove equal slopes. This diagnostic
differs from the additive model's overall F test. Summary methods preserve the
stored confidence limits and adjustment point without refitting or changing
the fitted result.

## Coefficients, intervals and predictions

Use the standard R methods directly on the ANCOVA result:

```r
coef(result)
vcov(result)
confint(result, parm = c("treatmentB", "baseline"), level = 0.9)
future <- data.frame(treatment = c("A", "B"), baseline = c(1, 2))
predict(result, future)
predict(result, future, interval = "confidence", level = 0.9)
predict(result, future, se.fit = TRUE)
predict(result) # selected analysis rows, in their stored order
```

The methods use `result$model`, the saved additive fit. `coef()` returns its
named coefficient vector, `vcov()` its model-based covariance matrix, and
`confint()` a matrix of coefficient confidence limits. Select coefficients by
name or position with `parm`. The methods preserve the corresponding native
`lm` behavior; they do not choose or refit another model. To inspect the
interaction model, use the same methods on `result$interaction_model`.

Prediction follows [`predict.lm()`](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/predict.lm.html),
including `se.fit`, `interval`, `level`, `type`, `terms`, `na.action`, `scale`,
`df`, `weights`, and `pred.var`. Its ordinary result is a named vector;
intervals produce a matrix with `fit`, `lwr`, and `upr` columns; `se.fit = TRUE`
returns a list with predictions, their standard errors, residual df and scale.
Term contributions retain the native matrix attributes and optional standard
errors. Missing predictors, empty/singleton inputs, unfamiliar treatment levels,
and warnings follow the installed R version's native method.

Omitting `newdata` uses the stored analysis rows, including any order imposed
by `subset`. It does not restore excluded rows from the original data frame.
New rows must supply the original treatment/covariate columns. Neither the
training data object nor a refit is needed to use a saved result after loading
PharmaStatsR. The saved additive model must remain an `lm` fit.

`confint()` intervals concern coefficients. Prediction confidence intervals
concern the mean response; prediction intervals add error variation for a
future observation. These are individual model-based intervals without
multiplicity or robust-covariance adjustments. New interval calls default to
`level = 0.95`; they do not inherit the `conf.level` used for the stored
adjusted means, and they do not overwrite those means or intervals.

For a weighted fit, specify the future observations' relative precision when
requesting prediction intervals:

```r
future$precision <- c(2, 4)
predict(weighted, future, interval = "prediction", level = 0.9,
        weights = ~precision)
```

The assumed future error variance is the fitted residual variance divided by
each new precision weight. `pred.var` can instead supply a chosen future error
variance. Native warnings and defaults for omitted prediction weights are
retained; training weights do not establish the precision of new observations.

## Residuals and fit statistics

The fitted result also supports standard inspection of the saved additive model:

```r
fitted(result)
residuals(result)
residuals(weighted, type = "pearson")
residuals(result, type = "partial")
c(n = nobs(result), residual_df = df.residual(result), SSE = deviance(result))
logLik(result)
logLik(result, REML = TRUE)
AIC(result)
BIC(result)
```

`fitted()` returns the fitted additive mean for each retained row. Default
residuals (`type = "working"`, also `"response"`) are the observed response
minus that mean. For a weighted fit, `"pearson"` and `"deviance"` multiply
the raw residual by the square root of its precision weight; they do not
divide by a residual standard deviation or adjust for leverage. `"partial"`
returns the native matrix of partial residuals, one column per model term.
`fitted.values()` and `resid()` are available aliases.

Vectors keep the stored analysis rows' names and order, including an explicit
subset order. They do not pad excluded input rows. `nobs()` counts retained
rows, not the sum of weights or all input rows. With additive rank `p` and
`n` retained rows, `df.residual()` is `n - p`. `deviance()` is residual SSE,
`sum(w * residual^2)` for precision weights `w`, and the ordinary sum of
squared residuals otherwise. These values concern the additive model, not
the interaction fit. For standardized residuals, leverage and Cook's distances,
use `pharma_model_diagnostics(result$model)`.

`logLik()` returns the native Gaussian likelihood with its `df`, `nobs` and
`nall` attributes. ML is the default and includes weight-dependent likelihood
constants. It estimates error variance using `SSE / n`; the residual variance
in `summary()` uses `SSE / (n - p)`. The likelihood's parameter count includes
the error variance. With `REML = TRUE`, its native `nobs` attribute is `n - p`,
while `nobs(result)` continues to count the retained rows.

`AIC()` and `BIC()` work through `logLik()` and use ML by default. Native
multi-model comparisons and `AIC(..., k = ...)` remain available. Compare
criteria only for the same observations and response scale, with comparable
likelihood and weighting assumptions. Do not compare REML likelihoods across
different fixed-effect designs. Native checks are retained, but they do not
establish that a comparison is valid or that a model is adequate. Inspect the
same measures on `result$interaction_model` when that separate fit is intended.

All these methods work with saved results after loading PharmaStatsR, without
the original training data or refitting. They preserve coefficients,
predictions, adjusted means, the interaction diagnostic and RNG state.

## Independent reference

The example uses baseline values `(0, 1, 2, 3)` in both treatment groups.
Group A follows `10 + 2*x`, group B follows `13 + 4*x`, and both receive the
orthogonal residual pattern `(1, -1, -1, 1)`.

For the additive model, coefficients are `(8.5, 6, 3)` with residual SSE `18`
and `5` residual degrees of freedom. The diagonal of `(X'X)^-1` is
`(19/40, 1/2, 1/10)`, giving standard errors
`sqrt((18/5) * c(19/40, 1/2, 1/10))`. Coefficient t statistics divide each
estimate by its SE, with two-sided p-values from the `t_5` distribution.
Total sum of squares is `180`, so R-squared is `0.9`, adjusted R-squared is
`0.86`, and the additive overall F statistic is `(162/2)/(18/5) = 22.5`
on `(2, 5)` degrees of freedom.

The interaction model has coefficients `(10, 3, 2, 2)`, residual SSE `8`, and
`4` residual degrees of freedom. Its partial interaction statistic is
`F = ((18 - 8)/1)/(8/4) = 5`, on `(1, 4)` degrees of freedom.

The overall covariate mean is `1.5`. Adjusted means from the additive model
are `13` for A and `19` for B. Each has SE `sqrt((18/5)/4) = sqrt(0.9)`,
and confidence limits use the `t_5` quantile at the requested level.

For a new row at baseline `x`, the mean-response variance is
`(18/5) * (1/4 + (x - 1.5)^2/10)` in either treatment group. Thus predictions
for `(A, 0)`, `(B, 2)`, `(A, 1.5)`, and `(B, 3)` are
`(8.5, 20.5, 13, 23.5)` with mean variances `(1.71, 0.99, 0.9, 1.71)`.
Ordinary prediction intervals add `18/5` to each variance before taking the
square root and multiplying by the relevant `t_5` quantile. Coefficient
intervals use the covariance matrix above and the same residual df.

Fitted values are `(8.5, 11.5, 14.5, 17.5, 14.5, 17.5, 20.5, 23.5)` and raw
residuals are `(2.5, -0.5, -1.5, -0.5, -0.5, -1.5, -0.5, 2.5)`. Thus
`nobs = 8`, residual df is `5`, and deviance is `18`. Gaussian ML log-likelihood
is `-4 * (log(2*pi) + 1 + log(18/8))`; its parameter count is `4` (three
coefficients plus error variance). AIC is `-2*logLik + 2*4`; BIC is
`-2*logLik + log(8)*4`. The determinant of `X'X` is `160`, giving REML
log-likelihood `-0.5 * (5*(log(2*pi) + 1 + log(18/5)) + log(160))`.

The [fit references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ancova-reference.R)
also verify affine response transformations and invariance of adjusted means
and the interaction F statistic to a common covariate translation.
The [summary references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ancova-summary.R)
check the coefficients, SEs, t tests and fit statistics above, plus native
correlation options, retained intervals, printing and saved results.

## Independent weighted reference

Use the same eight responses above with precision weights `1:8` and all rows.
For columns `(1, treatmentB, baseline)`, the exact cross-product matrix is:

```text
X' W X = [36  26   64]
          [26  26   44]
          [64  44  156]
```

Solving the weighted normal equations gives additive coefficients
`(296/45, 311/45, 167/45)`, weighted residual SSE `848/15`, and residual df
`5`. The diagonal of the inverse cross-product is
`(53/270, 19/135, 13/540)`; multiplying by `(848/15)/5` gives coefficient
variances. Coefficient tests use the native `t_5` reference.

The interaction coefficients are `(46/5, 147/41, 12/5, 354/205)`, with
weighted SSE `6948/205` and residual df `4`. Thus the partial F statistic is
`((848/15 - 6948/205)/1)/((6948/205)/4)`, on `(1, 4)` degrees of freedom.
At the unweighted baseline mean `1.5`, adjusted means are
`(1093/90, 343/18)` with variances `(12137/10125, 901/2025)`.
Their intervals use the `t_5` quantile at the requested confidence level.

The [weighted references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ancova-weights.R)
check these rational targets, direct native fits, weight-scale invariance,
contrasts, selected rows and levels, single evaluation, logical treatments,
saved-model summary/prediction and invalid configurations.

The [standard-method references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ancova-methods.R)
check coefficient covariance and intervals, the ordinary prediction targets
above, and weighted prediction variance `x0' V x0 + (848/75)/w0` for new
design row `x0` and precision `w0`. They also cover native option forwarding,
weight-scale invariance, missing/empty rows, selected-row order, saved fits,
and unchanged RNG state and model contents.

For the full weighted reference, `nobs = 8`, residual df is `5`, and deviance
is `848/15`. Raw residuals are `(199, 32, -45, -32, 23, -54, -41, 62)/45`.
The determinant of `X'WX` is `10800`. ML log-likelihood is
`0.5 * (sum(log(1:8)) - 8*(log(2*pi) + 1 + log((848/15)/8)))`;
REML log-likelihood is
`0.5 * (sum(log(1:8)) - 5*(log(2*pi) + 1 + log((848/15)/5))) - 0.5*log(10800)`.
A common positive rescaling of all precision weights scales deviance and
squared Pearson residuals by that factor, while preserving raw residuals,
fitted means, ML/REML likelihoods, AIC and BIC.

The [fit-statistic references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ancova-fit-statistics.R)
check these targets, partial residuals, subset order and counts, multi-model
criteria, weight rescaling, native attributes and saved results without refitting.

## Interpretation limits

The model assumes a linear covariate effect and independent errors with constant
variance, or variance proportional to the inverse precision weights. Treatment/covariate interaction should be considered substantively,
not accepted or rejected by a mechanical p-value rule. The helper does not
establish randomization validity, causal effects, baseline balance, normality,
homoscedasticity, absence of influential observations, or appropriateness of
using the overall covariate mean for a study estimand. The summary adds no
robust standard errors, multiplicity adjustment or post-selection correction.

Full arguments and return values: [ANCOVA fit help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_ancova.Rd)
[summary help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/summary.pharma_ancova.Rd),
and [residual/fit-statistic help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/residuals.pharma_ancova.Rd).
