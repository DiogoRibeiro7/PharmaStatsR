# Covariate mixed models with literal column names

`fit_covariate_model()` fits additive fixed effects and one random subject
intercept with nlme's default REML estimation. It returns a native `lme` object.
Use `repair_names = TRUE` when selected column names contain spaces, operators,
backticks, or R evaluation symbols. The default retains strict syntactic-name
validation and its existing native prediction interface.

## Fit and inspect the name map

```r
library(PharmaStatsR)
subject <- rep(1:4, each = 3)
time <- rep(c(-1, 0, 1), 4)
training <- data.frame(subject, time,
  y = 2 + 1.5 * time + rep(c(-3, -1, 1, 3), each = 3) +
    rep(c(1, -2, 1), 4)
)
names(training) <- c("subject id", "visit time", "response value")
model <- fit_covariate_model(
  training, "response value", "subject id", "visit time",
  repair_names = TRUE
)
model$column_map
#        role       original          model
# 1  response response value response.value
# 2        id     subject id     subject.id
# 3 covariate     visit time     visit.time
nlme::fixef(model) # intercept 2, slope 1.5
```

The backend reparses variable names internally, so quoting a name in a formula
does not suffice. Repair uses `make.names()` plus collision avoidance, including
names of unselected columns. Special names such as `...` and `..1` receive safe
aliases. Selected columns are renamed together: `body mass` and `body.mass`
remain distinct, with separate recorded aliases. Input names are never evaluated
as formula expressions.

The caller's data, values, factor attributes, and row order remain unchanged.
The model's stored data and formulas use backend names, as do coefficient and
summary labels. `column_map` translates those labels to original names and
records each role. It is present only when name repair is requested. Keep the
model and map intact when saving them; neither fitting nor prediction changes
the caller's object.

## Predict original columns

```r
future <- data.frame(subject = c(4, 999, 1), time = c(0, -1, 1),
                     row.names = c("known-a", "new-subject", "known-b"))
names(future) <- c("subject id", "visit time")
predict_covariate_model(model, future)
#     known-a new-subject     known-b
#         2.0         0.5         3.5
predict_covariate_model(model, future, level = 1)
# approximately 4.485714, NA, 1.014286
```

| Requested level | Prediction | Required columns | Unknown subject |
| --- | --- | --- | --- |
| `0` (helper default) | Fixed effects only | Original covariates | ID is unnecessary |
| `1` | Fixed effects plus the fitted subject intercept | Original covariates and ID | `NA`; no population fallback |

These level meanings follow [nlme prediction](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/predict.lme.html).
Native `predict.lme()` defaults to the highest grouping level; this helper
explicitly defaults to population predictions. Native prediction on a repaired
fit still expects backend names. `predict_covariate_model()` instead selects
original columns and applies the map, avoiding collisions with extra columns
that happen to have alias names. It also supports existing unmapped fits.

The response is unnecessary. All selected covariates must be present and
observed; required numeric values must be finite. Numeric covariates stay
numeric, logical covariates stay logical, and categorical covariates may be
factors or characters with levels known to the fitted model. Saved contrasts
apply even when later contrast options or new factor level order differ.
Missing predictors or required IDs raise errors rather than dropping rows.
Unknown subject IDs at level 1 are distinct from missing IDs.

Results are numeric vectors named with input row names, in input order.
Singleton and empty batches are supported, and extra columns are ignored.
The helper supplies point predictions only; it does not fit new subject effects,
impute, rescale, or calculate prediction intervals.

## Restore a saved model

```r
path <- tempfile(fileext = ".rds")
saveRDS(model, path)
restored <- readRDS(path)
stopifnot(identical(predict_covariate_model(restored, future, 1),
                    predict_covariate_model(model, future, 1)))
unlink(path)
```

In a fresh session, load PharmaStatsR, restore the result, and call the helper.
It registers the declared nlme dependency's methods as needed. No separate
backend attachment or refitting is required. The native model's stored training
data must remain available; handle the saved model accordingly.

## Numerical reference and boundaries

The fixed example is balanced: four subjects with three centered visits each,
intercept `2`, slope `1.5`, subject offsets `(-3, -1, 1, 3)`, and within-subject
residuals `(1, -2, 1)`. Orthogonality gives fixed-effect estimates `2` and `1.5`.
The residual sum of squares is `24` with `4*(3-1)-1 = 7` degrees of freedom, so
the REML residual variance is `24/7`. The between-subject mean square is
`3*20/(4-1) = 20`, giving random-intercept variance `(20 - 24/7)/3 = 116/21`.
The subject-effect shrinkage factor is `(116/21)/(116/21 + (24/7)/3) = 29/35`.
Thus conditional predictions add `29/35` times each subject's offset to the
population prediction. These are hand-derived references, not a second backend
fit treated as an independent calculation.

The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-lme-names.R)
check those references, rename invariance against direct nlme fits, literal
names in each role, selected/unselected name collisions, factor coding,
missing-row residual alignment, serialization, raw prediction batches, unknown
subjects, and invalid inputs/maps.

The [nlme model](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/lme.html)
remains an additive Gaussian model with a random subject intercept. Name repair
adds no random slopes, residual correlation structure, nonlinear effects, or
uncertainty intervals. Rows missing response, ID, or covariates are excluded at
fitting with `na.exclude`; response variation, full fixed-effects rank, sufficient
rows, and repeated subjects remain required. These checks do not guarantee
optimizer convergence or scientific adequacy.

This addition covers fitting and prediction. Existing diagnostic/report helpers
retain their documented `DV`/`Time` and native-prediction input requirements.
The [inventory](method-inventory.md) records the experimental support level.
