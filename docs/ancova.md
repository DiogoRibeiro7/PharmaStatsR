# ANCOVA with one continuous covariate

`pharma_ancova()` fits an additive ordinary linear model with exactly one
categorical treatment and one numeric covariate. It also fits the corresponding
treatment-by-covariate interaction model as a **common-slope diagnostic** and
reports treatment adjusted means at the overall observed covariate mean.

```r
result <- pharma_ancova(
  response ~ treatment + baseline,
  data = trial_data
)

coef(result$model)
result$slope_homogeneity
result$adjusted_means
```

The input formula must be additive and contain direct column names only. The
helper rejects extra predictors, interactions, missing/nonfinite model values,
a treatment with fewer than two observed levels, and a constant covariate.

## What is returned

- `model`: the additive ANCOVA `lm` fit.
- `interaction_model`: the treatment-by-covariate `lm` fit.
- `slope_homogeneity`: the nested-model partial F comparison.
- `adjusted_means`: treatment predictions at the overall observed covariate
  mean, with ordinary model-based confidence intervals.
- `covariate_mean`: the value used for adjustment.

A large interaction p-value does **not** prove equal slopes. It only records
that this particular interaction model comparison did not detect a departure at
the observed sample size.

## Independent reference

The reference fixture uses baseline values (0,1,2,3) in both treatment groups.
Group A follows (10+2x), group B follows (13+4x), and both receive the
orthogonal residual pattern ((1,-1,-1,1)).

For the additive model,

[
hateta=(8.5, 6, 3),
]

with residual SSE 18 and 5 residual degrees of freedom. The interaction model
has coefficients ((10,3,2,2)), residual SSE 8, and 4 residual degrees of
freedom. Therefore the partial interaction statistic is

[
F = rac{(18-8)/1}{8/4}=5.
]

The overall covariate mean is 1.5. Adjusted means from the additive model are
13 for A and 19 for B. Since the common-model MSE is (18/5), each adjusted
mean has standard error

[
sqrt{rac{18/5}{4}}=sqrt{0.9},
]

and confidence limits use the (t_5) quantile.

The tests also verify affine response transformations and invariance of adjusted
means and the interaction F statistic to a common translation of the covariate.

## Interpretation limits

The model assumes a linear covariate effect and ordinary linear-model error
structure. Treatment/covariate interaction should be considered substantively,
not accepted or rejected by a mechanical p-value rule. The helper does not
establish randomization validity, causal effects, baseline balance, normality,
homoscedasticity, absence of influential observations, or appropriateness of
using the overall covariate mean for a study estimand.

## R help

Full arguments and return values:
[`pharma_ancova()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_ancova.Rd).
