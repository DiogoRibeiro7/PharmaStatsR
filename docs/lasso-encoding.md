# Categorical encoding inside LASSO folds

Set `encode = TRUE` in `screen_covariates_lasso_imputed()` to fit numeric
imputation and categorical encoding separately inside each training fold.
The default remains numeric-only. The opt-in mode accepts numeric, character,
factor, and logical candidates; the response remains numeric and Gaussian.

## Fit raw candidates

```r
library(PharmaStatsR)
block <- data.frame(
  x = c(-1, -1, 1, 1, NA, NA), group = rep(c("A", "B"), 3),
  y = c(-5, 1, -1, 5, -3, 3)
)
training <- block[rep(seq_len(6), 3), ]
encoded <- screen_covariates_lasso_imputed(
  training, "y", c("x", "group"), lambda = c(4, 2, 1, 0.5),
  encode = TRUE, foldid = rep(1:3, each = 6)
)
encoded$cv
#   lambda        mse
# 1    4.0 11.6666667
# 2    2.0  6.6666667
# 3    1.0  2.0000000
# 4    0.5  0.5000000
encoded$selected # "x" "group"
encoded$encoding$columns # "x" "groupA" "groupB"
encoded$fold_imputation[[1]] # only x is imputed, with training mean zero
encoded$fold_encoding[[1]] # encoding learned without fold 1
```

Each fold fits numeric replacements or donors, completes the numeric training
values, fits `fit_encoding()` on those training rows, and fits glmnet on that
design. Held-out rows use `apply_imputation()` or `apply_knn_imputation()` and
`apply_encoding()` with those saved parameters. Standardization is learned by
the fold's glmnet model. The response and subject identifier never enter
preprocessing. Subject folds, excluded missing-response rows, explicit penalty
grids, and observation-weighted tuning MSE follow the
[screening guide](lasso-imputation.md).

`method = "median"` changes the numeric summary. `method = "knn"` uses numeric
candidates as targets and all selected raw candidates as distance predictors:

```r
encoded_knn <- screen_covariates_lasso_imputed(
  training, "y", c("x", "group"), lambda = c(4, 2, 1, 0.5),
  encode = TRUE, method = "knn", k = 2, foldid = rep(1:3, each = 6)
)
encoded_knn$cv # same fixed reference values for this balanced example
```

kNN excludes the current target from its own distance and reuses training-only
donors and scales. Distances use the raw categorical values, before design
encoding; see the [distance contract](fitted-knn.md). `k` and distance weights
are fixed, not tuned. A kNN call needs at least one numeric target and another
positive-weight distance predictor. Mean/median can fit categorical-only designs
and return an empty numeric replacement table. Every fitted design needs at
least two columns and one varying column.

## Levels, missingness, and coding

Categorical values must be observed. A missing category fails with training,
held-out, or prediction context; there is no category imputation, pooling, or
silent row removal. Numeric missingness retains the selected imputer's rules.

Characters learn levels only from each training subset. A held-out category
absent from that subset raises an error. A character predictor with only one
training category cannot define a recipe. Factors retain declared levels,
including unused ones; define them from a prespecified schema or training data,
not by inspecting all held-out values. A declared but unobserved category is
accepted, but its effect cannot be estimated from those training observations.
Logical candidates use their fixed `FALSE`/`TRUE` schema.

The [saved encoder](fitted-encoding.md) uses an additive no-intercept design:
the first categorical term has full indicators, and later terms follow the
contrasts active during fitting. Ordered factors and custom contrasts follow
the same rule. glmnet supplies the intercept and standardizes design columns.
The recipe stores actual coding, so later contrast options cannot alter
prediction. Ambiguous encoded names are rejected.

The penalty applies to individual design columns. Coding and candidate order
can affect the penalty and selected columns; this is not group LASSO or a test
of a categorical effect. Full indicators and the intercept are redundant, so
individual coefficients may be nonunique. `selected_columns` records nonzero
final design columns; `selected` maps any such column back to its raw candidate,
in input order. Do not interpret this mapping as inference.

## Predict with the saved recipe

```r
future <- data.frame(group = c("B", "A"), x = c(NA, 1),
                     row.names = c("new-a", "new-b"))
predict_lasso_imputed(encoded, future)
#         lambda_4
# new-a   2.500000
# new-b  -1.112372
predict_lasso_imputed(encoded_knn, future)
```

Supply every original raw candidate, including those with zero coefficients.
The helper applies numeric imputation, the final saved encoding, and the final
model in that order. It restores encoded column order, accepts only fitted
penalties, preserves rows, and never learns from the prediction batch. Empty
batches and singleton categories are supported. Unknown or missing categories
fail. Factors or characters may supply saved categorical values; logical
candidates must stay logical. kNN also enforces its saved distance schema.

Save the entire result with `saveRDS()` and restore it with `readRDS()`.
`predict_lasso_imputed()` works after loading PharmaStatsR in a fresh session;
separately attaching glmnet is unnecessary. New encoding entries are present
only for `encode = TRUE`: `encoding`, `fold_encoding`, and `selected_columns`.
Numeric-only saved results keep their existing behavior. Do not edit recipes.

## Independent numerical reference

In the example, imputed `x` is centered with population variance `2/3`; let
`z` equal `-1` in A and `1` in B. It is orthogonal to `x` and `y = 2*x + 3*z`.
The complementary group indicators span `z`. For LASSO with standardized columns,
the fitted prediction is

```text
x * max(2 - lambda * sqrt(3/2), 0) + z * max(3 - lambda, 0).
```

This follows by soft-thresholding the orthogonal terms in the
[Gaussian penalized objective](https://glmnet.stanford.edu/articles/glmnet.html#linear-regression-family--gaussian-default).
The held-out MSE at penalties `4, 2, 1, 0.5` is `35/3, 20/3, 2, 0.5`.
These prediction and MSE references do not rely on a second glmnet call or on
one particular redundant indicator coefficient representation.

The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-lasso-encoding.R)
also fix asymmetric numeric replacements and categorical kNN donor choices;
perturb held-out rows without changing their fold's fitted preprocessing;
and cover declared/unknown levels, changed contrasts, serialization, literal
names, categorical-only designs, response exclusions, subject folds, and invalid
saved inputs. This remains an experimental Gaussian screening procedure.
Minimum tuning error needs independent evaluation or outer resampling; neither
encoding nor single imputation adds missing-data uncertainty, prediction
intervals, or post-selection inference.
