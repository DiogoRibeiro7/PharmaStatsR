# Saved nearest-neighbor imputation

`fit_knn_imputation()` saves numeric training targets, mixed predictors, and
distance scales. `apply_knn_imputation()` fills new numeric targets from those
training donors. Adding, removing, or changing another new row cannot change
a recipient's imputation.

Select predictors explicitly, excluding outcomes, identifiers, and information
unavailable at prediction time. Split data before fitting. The model retains
selected training data, unlike the summary table from `fit_imputation()`.

```r
library(PharmaStatsR)
training <- data.frame(value = c(10, 20), x = c(0, 10), group = c("a", "b"))
model <- fit_knn_imputation(training, "value", c("x", "group"), k = 1)
future <- data.frame(value = c(NA, 99), x = c(2, 1000), group = c("a", "b"))
apply_knn_imputation(future, model)
#   value    x group
# 1    10    2     a
# 2    99 1000     b
```

The first recipient has distances `(0.2 + 0) / 2 = 0.1` and
`(0.8 + 1) / 2 = 0.9`, so the closest donor supplies 10. With `k = 2`, the
replacement is 15. The observed 99 stays unchanged and never becomes a donor.

## Distance and donor rules

The mixed-data calculation follows the available-pair weighted-average
structure described in the [cluster Gower documentation](https://stat.ethz.ch/R-manual/R-patched/library/cluster/html/daisy.html).
This fitted implementation freezes training ranges and additionally caps new
numeric contributions at one:

- Numeric predictors use absolute differences divided by their observed
  training range. Ranges use all training rows, including rows missing a target.
  For example, a training range of 0–10 and a new value of 15 gives contributions
  1 and 0.5 against donors 0 and 10. Values themselves are not clipped.
- Ordered factors use integer codes in their declared training level order,
  scaled by the observed training code range. New factors or characters use
  that saved order; unseen observed levels raise an error.
- Character and unordered factors use zero for a match and one otherwise.
  Unseen nominal values are permitted and mismatch different donor values.
  Logical predictors use the same symmetric rule, including `FALSE` matches.
- Constant training predictors contribute zero when both values are observed.
  Missing pairs contribute neither distance nor weight. An entirely missing
  training predictor never contributes, even if new values are observed.
- Named nonnegative `weights` default to one for omitted predictors. A zero
  weight excludes a predictor before value checks or storage; it need not be
  present in new data. Each target needs another positive-weight predictor.

For each target, only training rows with observed target values can donate.
Choose up to `k` comparable donors; fewer than `k` is allowed. Exact distance
ties follow training row order. Average their target values with equal weights;
predictor weights affect selection, not this mean. With no comparable donor,
leave the target missing and emit one warning per affected target with a count.

The current target is excluded from its own distances. When several targets
also serve as predictors, each calculation uses the original new-data values.
Earlier imputations never feed later ones. This avoids target-order effects.

## Save and apply within folds

```r
path <- tempfile(fileext = ".rds")
saveRDS(model, path)
restored <- readRDS(path)
stopifnot(identical(apply_knn_imputation(future, restored),
                    apply_knn_imputation(future, model)))
unlink(path)
```

The plain versioned model retains selected training target values and transformed
predictor values, with names, weights, ranges, and ordered levels. Handle the
saved model as training data. Unrelated columns are excluded; do not edit its
internal structure.

Fit a new model using only the training partition of every validation fold,
then apply it to that fold's held-out rows. Keep subjects together when
evaluating new subjects. Prespecify ordinal levels or derive them from training
data. Tuning `k` or weights requires the same separation and an outer evaluation
of the selected procedure.

This pair is separate from [numeric LASSO fold imputation](lasso-imputation.md),
which supports mean/median replacements only. The original `impute_ml()` still
uses donors and scales from its supplied dataset and supports categorical targets;
this saved model supports numeric targets and Gower distance only.

## Boundaries and evidence

Targets must be finite real numeric vectors or missing (`NA`/`NaN`), with at
least one observed training value each. Empty target selections are rejected.
Numeric and logical predictors must retain their types. Explicit `NA` factor
levels, infinite selected numeric values, and unsupported predictor types raise
errors. Ordinary missing values and empty new datasets are allowed. Names match
literally; row identity, column order, unselected columns, and observed targets
are preserved. Integer targets may become double.

The [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-fitted-knn.R)
cover hand-calculated distances and means, an in-range `cluster::daisy()`
comparison, frozen-range and batch independence, noncascading targets, weights,
ties, missing pairs, extreme numeric ranges, categorical contracts, serialization,
and invalid inputs. These experimental helpers perform single imputation;
they do not quantify missing-data uncertainty or establish missingness assumptions.
