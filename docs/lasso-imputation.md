# LASSO screening with training-fold imputation

`screen_covariates_lasso_imputed()` learns numeric mean/median replacements or
nearest-neighbor donors inside each training fold, fits a Gaussian penalized
model, and predicts that fold's held-out observations. It returns the selected predictors, tuning scores,
held-out predictions, each fold's imputation model, and a final model with its
saved imputation parameters. The API is experimental.

Pass the raw numeric development data and a prespecified penalty grid. An
imputation or other learned transformation applied before this call is not
undone. Keep an independent test set or outer resampling loop for evaluating the
chosen procedure: the minimum error used to choose a penalty is a tuning result,
not an unbiased estimate of future performance.

## Fit and inspect

This small orthogonal example has deliberately simple reference values:

```r
library(PharmaStatsR)

block <- data.frame(
  x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
  y = c(-2, -2, 2, 2, 0, 0)
)
training <- block[rep(seq_len(6), 3), ]
training$SubjectID <- rep(1:9, each = 2)
folds <- rep(1:3, each = 6)

result <- screen_covariates_lasso_imputed(
  training, "y", c("x1", "x2"), lambda = c(2, 1, 0.5),
  id = "SubjectID", foldid = folds
)
result$selected # "x1"
result$cv
#   lambda       mse
# 1    2.0 2.6666667
# 2    1.0 1.0000000
# 3    0.5 0.2500000
result$lambda.min # 0.5
result$fold_imputation[[1]] # x1 and x2 replacements are both zero
```

The grid must have at least two distinct, finite, strictly positive values; the
helper sorts them in decreasing order. Choose it independently of the held-out
outcomes and preprocessing statistics. It does not derive a master grid from a
full-data fit. Every fold and the final fit must cover the complete requested
path; incomplete or nonfinite backend results raise errors.

Each call to `glmnet()` uses a Gaussian response, an intercept, and predictor
standardization estimated within that fit. `alpha = 1` uses LASSO; values between
zero and one use elastic net, while zero uses ridge and generally does not give
sparse selection. `result$alpha` retains the supplied value. See the backend's [Gaussian objective and standardization
contract](https://cran.r-project.org/web/packages/glmnet/glmnet.pdf).

Selection uses the smallest mean squared error across all retained held-out
observations. Exact ties select the largest penalty. Subjects with more retained
rows contribute more to this score; keeping a subject together in a fold does
not give subjects equal weights or model within-subject correlation. There is
no one-standard-error rule or tuning of `alpha` in this helper.

## Folds, missingness, and row identity

- Only missing responses (`NA` or `NaN`) are excluded. Missing predictor values
  stay in the development sample and are imputed from the relevant training
  fold. The response is never imputed.
- Every training fold needs at least one observed value in every predictor, a
  varying response, and at least one varying predictor after imputation. An
  all-missing held-out predictor is allowed when it can be imputed. With kNN,
  every missing entry also needs comparable training donors. Unusable sets raise an
  error naming the fold; they are not silently dropped or fitted globally.
- `foldid` must contain one positive integer per original row. After excluding
  missing responses, surviving labels are renumbered in sorted order; at least
  three nonempty folds must remain. With `id`, each retained subject must occupy
  exactly one fold, and its identifier must be present.
- Without explicit folds, `nfolds` defaults to ten. Random assignment balances
  subjects when `id` is supplied, otherwise rows. Use `set.seed()` to reproduce
  it. Explicit folds do not consume the RNG to generate a split.
- `result$predictions` has the original row names and order. Its columns align
  with rows of `result$cv`. Excluded response rows contain `NA`, as do their
  entries in `result$foldid`. Missing-predictor rows receive predictions.
- `result$fold_imputation` stores the training replacement table or saved donor
  model for each normalized fold, so the fitted preprocessing can be inspected.
- `result$method` records the chosen method; `result$covariates` records the
  complete predictor order needed when predicting new data.

For example, if three folds have observed predictor values `(1, 2)`, `(3, 9)`,
and `(8, 20)`, their training-only mean replacements are `10`, `31/4`, and
`15/4`; the medians are `17/2`, `5`, and `5/2`. The full-development replacements
are different: mean `43/6` and median `11/2`. Tests fix each value explicitly.

## Nearest-neighbor preprocessing within folds

Set `method = "knn"` to use [saved nearest-neighbor imputation](fitted-knn.md).
The default remains `"mean"`; `"median"` is unchanged. `k` and `weights` apply
only to kNN and are fixed during this call, not tuned.

```r
knn_result <- screen_covariates_lasso_imputed(
  training, "y", c("x1", "x2"), lambda = c(2, 1, 0.5),
  method = "knn", k = 2, id = "SubjectID", foldid = folds
)
knn_result$cv # MSE: 8/3, 1, 1/4 for this reference
knn_result$method # "knn"
knn_result$fold_imputation[[1]]$k # 2
```

Each training partition supplies its own donor values and numeric ranges.
All selected numeric covariates are both targets and distance predictors,
excluding the current target from its own distances. The outcome and subject ID
never enter the donor model. The same saved model completes training and
held-out rows before fitting/predicting with the Gaussian path. Standardization
is then estimated from that fold's completed training matrix.

Distances use available-pair weighted Gower contributions, bounded at one for
values outside the saved training range. Average up to `k` comparable donor
targets; exact distance ties follow original training row order. Earlier
imputations never feed later targets, and held-out rows cannot become donors
or alter each other's imputations. Missing training target values never donate.

Named `weights` affect distances, not the donor mean or MSE. Omitted weights
are one. Zero weights exclude distance predictors, while those columns remain
imputation targets and model candidates. Each target needs another positive
weight predictor. See the [distance rules](fitted-knn.md#distance-and-donor-rules).

If the standalone imputer would leave an entry missing because no comparable
donors exist, screening stops with the affected training/held-out fold and
target. It does not drop those rows or substitute a different imputation method.
For example, a row missing every candidate predictor cannot be completed.

In the reference above, the first two closest donors for each missing `x1`
have values -1 and 1, so the imputed value is zero. The analytic coefficients
and MSE below therefore apply to this kNN example too. A second fixed case uses
folds with observed `x1` pairs `(1,2)`, `(3,9)`, `(8,20)`, located at `x2=-1,0`,
and missing `x1` at `x2=1`. For `k=1`, the three training-fold replacements
are **9, 2, 2**, while the full-data replacement is **2**. These values differ
from mean/median replacements and are fixed independently of the backend fit.

The [kNN screening tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-lasso-knn.R)
check those completions and model predictions, training-only ranges and donors,
held-out perturbations, response/ID exclusion, weights, noncascading targets,
row identity, serialization, and unusable-fold errors.

After tuning, `knn_result$imputation` is a fresh donor model fitted on all
retained development rows. Reuse it to complete new predictors:

```r
knn_future <- data.frame(x1 = c(NA, 1, -1), x2 = c(1, -1, 1))
predict_lasso_imputed(knn_result, knn_future)
# approximately 0, 1.387628, -1.387628
```

Saving a kNN screening result retains selected training predictor values in
each fold model and the final model. It contains multiple training partitions,
so its size grows with the number of folds and rows. Keep `k` and weights fixed
in advance or evaluate their selection in an outer resampling design.

## Reuse the final model

After tuning, the helper fits fresh imputation parameters and a model path on all
retained development rows. `selected` contains the nonzero coefficients from
that final fit at `lambda.min`, in the requested predictor order. The final
model and the held-out predictions have different roles.

```r
new_data <- data.frame(x1 = c(NA, 1, -1), x2 = c(1, -1, 1))
predicted <- predict_lasso_imputed(result, new_data)
predicted
# approximately 0, 1.387628, -1.387628
```

[`predict_lasso_imputed()`](predict-lasso-imputed.md) chooses the saved
mean/median or kNN imputer and restores the full candidate order, including
predictors whose coefficients were shrunk to zero. It does not impute from new
rows or rescale them. All raw candidate columns are required; no response or
subject identifier is needed.

Persist the result with `saveRDS()` and restore it with `readRDS()`. In a fresh
session, load PharmaStatsR and use the same helper; it registers the glmnet
methods as needed. Older mean/median results without method/order metadata
remain supported through their original replacement table.

The default predicts at `lambda.min`; an explicit `lambda` vector must use
values from `result$cv$lambda`. Columns `lambda_j` correspond to rows of that
table and retain request order. Missing comparable kNN donors cause an error.
The [prediction guide](predict-lasso-imputed.md) covers empty/singleton data,
reordered penalties, saved-result consistency checks, and numerical references.

## Independent numerical references

For the example above, the imputed `x1` has mean zero and population variance
`2/3`. The second predictor has variance one and is orthogonal to the first and
to the response. The intercept and second slope are zero. With standardized
predictors, the first LASSO slope in original units is

\[
\hat\beta_1(\lambda)=\max\{2-\lambda\sqrt{3/2},0\}.
\]

Every training fold has the same predictor distribution. Predictions are the
completed first predictor times this slope. Therefore the held-out MSE is
`(2/3) * (2 - beta1)^2`, giving exactly `8/3`, `1`, and `1/4` at the three
penalties. These targets are calculated without another model fit.

A second reference has fold sizes one, two, and three, responses `1:6`, and
penalties large enough for intercept-only models. Held-out predictions are
`(4, 4, 4, 2, 2, 2)`, yielding squared errors `(9, 4, 1, 4, 9, 16)` and MSE
`43/6`. This distinguishes observation weighting from an unweighted average of
the three fold errors and verifies the exact-tie rule.

The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-lasso-imputed.R)
also check manual fold-by-fold backend comparisons, held-out perturbations,
subject integrity, row alignment, serialization, literal names, and failures for
invalid inputs or incomplete model paths.

## Scope and existing workflows

`screen_covariates_lasso()` retains its complete-case, numeric-only behavior and
character-vector return. The new helper returns a list and retains rows with
missing predictors; this is an explicit choice of a different screening
procedure. It does not change the existing function's defaults.

This implementation supports numeric mean/median and nearest-neighbor imputation. The
[saved categorical encoder](fitted-encoding.md) remains a separate manual
transformation; categorical preprocessing is not integrated into this screening loop. Single-value imputation does not quantify
missing-data uncertainty or establish missingness assumptions. Gaussian
screening is not mixed-effects selection or post-selection inference.
