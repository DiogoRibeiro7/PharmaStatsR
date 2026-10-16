# Predict from saved screening results

`predict_lasso_imputed()` applies the final imputer and Gaussian model saved by
`screen_covariates_lasso_imputed()`. It handles mean, median, and nearest-neighbor
imputation, restores the complete training predictor order, and returns a
numeric prediction matrix. No new-data statistics are fitted.

## Fit once and predict raw new rows

```r
library(PharmaStatsR)
block <- data.frame(
  x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
  y = c(-2, -2, 2, 2, 0, 0)
)
training <- block[rep(seq_len(6), 3), ]
result <- screen_covariates_lasso_imputed(
  training, "y", c("x1", "x2"), lambda = c(2, 1, 0.5),
  method = "knn", k = 2, foldid = rep(1:3, each = 6)
)
future <- data.frame(x2 = c(1, -1, 1), x1 = c(NA, 1, -1),
                     row.names = c("new-a", "new-b", "new-c"))
predict_lasso_imputed(result, future)
#         lambda_3
# new-a   0.000000
# new-b   1.387628
# new-c  -1.387628
```

Column order in `future` differs from training; the helper restores it. Include
every candidate predictor, even `x2`, whose final coefficient is zero. A response
and subject ID are unnecessary; extra columns are ignored. Supply raw predictors
without separately imputing or scaling them. The model's coefficients already
account for training standardization.

In this fixed example, the two nearest donors fill missing `x1` with zero.
The first slope is `max(2 - lambda * sqrt(3/2), 0)`, and the intercept and second
slope are zero. These analytic values underpin the tests; the
[screening guide](lasso-imputation.md#independent-numerical-references) derives them.

## Choose penalties from the fitted grid

Omitting `lambda` uses `result$lambda.min`. Explicit requests must be distinct
values from `result$cv$lambda`. Their order is preserved:

```r
predict_lasso_imputed(result, future, lambda = c(0.5, 2))
#         lambda_3 lambda_1
# new-a   0.000000        0
# new-b   1.387628        0
# new-c  -1.387628        0
```

Column `lambda_j` refers to row `j` of `result$cv`. The result remains a matrix
for a single row or penalty; an empty new data frame produces zero rows with
the requested columns. Input row names and order are retained.

The backend can interpolate or refit for new penalties, as described in the
[glmnet prediction reference](https://glmnet.stanford.edu/reference/predict.glmnet.html).
This helper selects columns from the already fitted path. It rejects new values
such as 0.75, including values between fitted penalties. It performs no model
selection, refitting, or extrapolation in penalty space.

## Restore saved results

```r
path <- tempfile(fileext = ".rds")
saveRDS(result, path)
restored <- readRDS(path)
stopifnot(identical(predict_lasso_imputed(restored, future),
                    predict_lasso_imputed(result, future)))
unlink(path)
```

In a fresh R session, load PharmaStatsR, read the result, and call the helper.
It loads the declared glmnet dependency to register its prediction methods.
Older mean/median results from before the `method` and `covariates` fields were
introduced are also accepted when their original replacement table provides
both. Current results use the explicit metadata and check it against the saved
imputer and fitted coefficient order. Do not edit fitted results.

kNN results retain selected training predictor values in their donor models.
Save and handle them as training data. New rows never become donors or change
one another's imputation. If a missing target has no comparable saved donor,
prediction stops with an error naming the target; it does not drop that row
or fall back to a different method. Mean/median results can fill wholly missing
new predictor rows using the saved replacements.

## Scope and evidence

These are final-model predictions from all retained development rows, not the
held-out values in `result$predictions`. Evaluate the selected procedure on
independent data or outer resampling. No prediction intervals, imputation
uncertainty, or post-selection inference are added.

The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-predict-lasso.R)
cover analytic predictions at selected and reordered penalties, fixed asymmetric
mean/median/kNN replacements, unchanged batches, literal/reordered names,
serialization and historical metadata, empty/singleton rows, nonfinite outputs,
inconsistent saved inputs, and no-donor errors. Tests also prevent fitting or
rescaling during prediction. The [inventory](method-inventory.md) records the
experimental support level.
