# Reuse training imputation parameters

`fit_imputation()` estimates numeric mean or median replacements from training
data. `apply_imputation()` fills missing entries using that saved table, without
estimating anything from the data being transformed. Both are experimental APIs.

Split observations before fitting preprocessing. For repeated measurements,
keep all observations from the same subject together when evaluating predictions
for new subjects. Choose the validation unit and split for the analysis first;
these functions do not choose a split or assess its suitability.

## Fit once and apply

```r
library(PharmaStatsR)

training <- data.frame(x = c(1, NA, 3, 8))
validation <- data.frame(x = c(NA, 100, NaN))
params <- fit_imputation(training, "x", method = "mean")
params
#   var value method
# 1   x     4   mean
apply_imputation(validation, params)
#     x
# 1   4
# 2 100
# 3   4
```

The training replacement is `(1 + 3 + 8) / 3 = 4`. A median fit would save `3`,
the middle observed training value. The held-out value `100` has no role in
either estimate. The existing `impute_mean()` and `impute_median()` continue to
estimate and fill within the single table passed to them; use the fit/apply pair
when the replacement must be reused on another table.

The returned plain data frame contains `var`, `value`, and `method`, in the
requested variable order. To persist it, use `saveRDS(params, "imputation.rds")`
and reload with `readRDS("imputation.rds")`. `apply_imputation()` uses `var` and
`value`; the `method` column is metadata, and additional columns are ignored.
Column names match literally, including spaces and punctuation.

## Combine with saved scaling

Fit scaling on the completed training data, then apply both saved transformations
to the held-out data in the same order:

```r
completed_training <- apply_imputation(training, params)
scaling <- center_scale(completed_training, "x")
completed_validation <- apply_imputation(validation, params)
scaled_validation <- apply_center_scale(completed_validation, scaling$params)
```

Here the completed training values are `(1, 4, 3, 8)`, with mean `4` and sample
standard deviation `sqrt(26 / 3)`. The missing validation entries become zero
after scaling. Scaling still requires a nonconstant training column with at
least two observations; imputation alone permits singleton or constant columns.
The [scaling reference](scaling-reference.md) records the independent sample-SD
targets, fallback for extreme units, and remaining floating-point limits.

## Refit inside every training fold

An outer training/test split does not protect the validation folds inside a
subsequent tuning procedure. Fit fresh parameters inside each training fold.
This small example holds out entire subjects and returns the held-out rows in
their original order:

```r
repeated <- data.frame(
  SubjectID = rep(1:3, each = 2),
  x = c(1, NA, 3, NA, 8, NA)
)
folds <- repeated$SubjectID
completed <- repeated
for (fold in sort(unique(folds))) {
  held_out <- folds == fold
  fold_params <- fit_imputation(repeated[!held_out, , drop = FALSE], "x")
  held_out_data <- apply_imputation(
    repeated[held_out, , drop = FALSE], fold_params
  )
  completed$x[held_out] <- held_out_data$x
}
completed$x
# [1] 1.0 5.5 3.0 4.5 8.0 2.0
```

The three training means are `5.5`, `4.5`, and `2`. If scaling or another learned
transformation is also used, fit it on each fold's completed training data and
apply its saved parameters to that fold's held-out rows before fitting/scoring
the model. This example demonstrates preprocessing only, not a performance
estimate. After choosing a model using valid resampling, fit its preprocessing
on all development training data for use on future data.

`screen_covariates_lasso()` still delegates to `cv.glmnet()` without a
fold-specific imputation hook. Passing a globally imputed table to it does not
refit imputation inside its folds. [Saved categorical encoding](fitted-encoding.md)
can be composed with these helpers manually. For numeric Gaussian screening,
[`screen_covariates_lasso_imputed()`](lasso-imputation.md) now fits replacements
and standardization inside each training fold for a prespecified penalty grid.
The separate [saved nearest-neighbor pair](fitted-knn.md) now reuses training
donors and scales; the numeric screening helper integrates it with
`method = "knn"`. Categorical preprocessing inside screening folds remains
a separate follow-up.

## Boundaries and evidence

- Selected training columns must contain at least one observed real numeric
  value. All-missing or empty selected training columns raise an error.
- New numeric columns may be empty, constant, or entirely missing. `NA` and
  `NaN` are filled; observed values, row identity, and unselected columns remain
  unchanged. Integer targets may become double when a replacement is applied.
- Infinite selected values, nonnumeric targets, ambiguous names, and nonfinite
  or malformed saved parameters raise errors. No columns are inferred: select
  predictor columns explicitly, excluding outcomes/identifiers as appropriate.
- An empty variable selection produces an empty valid parameter table and
  applying it leaves the input unchanged.
- These are single-value replacements. They do not quantify missing-data
  uncertainty, establish valid missingness assumptions, or perform multiple
  imputation. Neither helper changes the existing imputation functions.

The [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-fitted-imputation.R)
fix arithmetic means, medians, completed datasets, and the imputation/scaling
composition. They also check held-out perturbations, subject folds, literal
names, serialization, and input boundaries. The [inventory](method-inventory.md)
records the support level and evidence scope.
