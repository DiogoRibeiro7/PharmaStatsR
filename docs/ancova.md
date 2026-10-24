# ANCOVA with one continuous covariate

`pharma_ancova()` fits an additive ordinary linear model with exactly one
categorical treatment and one numeric covariate. It also fits the corresponding
treatment-by-covariate interaction model as a common-slope diagnostic and
reports treatment adjusted means at the overall observed covariate mean.

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
- `adjusted_means`: treatment predictions at the overall observed covariate
  mean, with individual model-based confidence intervals.
- `covariate_mean`: the value used for adjustment.
- `treatment` and `covariate`: detected column names.

A large interaction p-value does not prove equal slopes. This diagnostic
differs from the additive model's overall F test. Summary methods preserve the
stored confidence limits and adjustment point without refitting or changing
the fitted result.

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

The [fit references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ancova-reference.R)
also verify affine response transformations and invariance of adjusted means
and the interaction F statistic to a common covariate translation.
The [summary references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ancova-summary.R)
check the coefficients, SEs, t tests and fit statistics above, plus native
correlation options, retained intervals, printing and saved results.

## Interpretation limits

The model assumes a linear covariate effect and ordinary linear-model error
structure. Treatment/covariate interaction should be considered substantively,
not accepted or rejected by a mechanical p-value rule. The helper does not
establish randomization validity, causal effects, baseline balance, normality,
homoscedasticity, absence of influential observations, or appropriateness of
using the overall covariate mean for a study estimand. The summary adds no
robust standard errors, multiplicity adjustment or post-selection correction.

Full arguments and return values: [ANCOVA fit help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_ancova.Rd)
and [summary help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/summary.pharma_ancova.Rd).
