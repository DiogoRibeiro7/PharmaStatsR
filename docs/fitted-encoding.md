# Reuse training covariate encoding

`fit_encoding()` saves categorical levels, numeric coding, and matrix column
order from training data. `apply_encoding()` builds the same columns for new
data, including a batch containing only one known category. Both APIs are
experimental; the existing `prepare_model_matrix()` remains available for
constructing a matrix from a single table.

Split data before fitting. Character columns learn levels from observed training
values. Factors retain all declared levels, including unused ones. Define those
levels from a prespecified schema or training data: creating factors from the
whole dataset before splitting can expose held-out categories. For repeated
measurements, keep subjects together when the evaluation targets new subjects.

## Fit once and apply

```r
library(PharmaStatsR)

training <- data.frame(x = c(10, 20, 30), group = c("A", "B", "C"))
recipe <- fit_encoding(training, c("x", "group"))
apply_encoding(training, recipe)
#    x groupA groupB groupC
# 1 10      1      0      0
# 2 20      0      1      0
# 3 30      0      0      1

validation <- data.frame(x = c(100, NA), group = c("B", NA))
apply_encoding(validation, recipe)
#     x groupA groupB groupC
# 1 100      0      1      0
# 2  NA     NA     NA     NA
```

The matrix has additive main effects and no intercept. Numeric values pass
through; missing values stay missing and rows are retained. The first
categorical term uses full indicator coding; later terms follow the contrasts
active during fitting. Ordered factors and custom contrast matrices are
supported. R's [model-matrix documentation](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/model.matrix.html)
describes this term coding and its `assign`/`contrasts` metadata.

The recipe saves the actual numeric coding blocks. Applying it does not consult
current contrast options or require custom contrast functions to remain
available. It also ignores new factors' level order and unused declared levels.
The result is a plain numeric matrix with saved column names/order and input row
names/order; `model.matrix()`'s `assign` and `contrasts` attributes are not copied.

An observed new category such as `"D"` raises an error identifying the variable
and level. It is not silently converted to the reference category or missingness.
If the analysis needs an explicit other category, define its scientific meaning
and recoding policy before fitting and use that policy consistently. No category
pooling is performed by these helpers.

## Save the recipe

The plain list contains `version = 1L`, `variables`, and ordered `columns`.
Each named variable specification records its `kind`, output `columns`, and
numeric `coding` matrix; numeric variables have `coding = NULL`. Matrix row names
record categorical levels. Logical variables use `FALSE` and `TRUE`, regardless
of which were observed in training, following R's
[logical contrast convention](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/contrasts.html).

Use `saveRDS(recipe, "encoding.rds")` and `readRDS("encoding.rds")` to persist it.
No training rows, formulas, contrast functions, or environments are retained.
Keep the recipe intact; application validates its version and schema.

## Combine with imputation and scaling

Fit each transformation on training data, in the order in which it will be
applied. This example reuses the training mean `4` and sample standard deviation
`sqrt(26 / 3)` before encoding:

```r
training <- data.frame(x = c(1, NA, 3, 8), group = c("A", "B", "A", "B"))
imputation <- fit_imputation(training, "x")
completed_training <- apply_imputation(training, imputation)
scaling <- center_scale(completed_training, "x")
encoding <- fit_encoding(scaling$data, c("x", "group"))

validation <- data.frame(x = c(NA, 100), group = c("B", "A"))
completed_validation <- apply_imputation(validation, imputation)
scaled_validation <- apply_center_scale(completed_validation, scaling$params)
apply_encoding(scaled_validation, encoding)
# x is 0 and 96 / sqrt(26 / 3); both groupA and groupB remain present
```

Refit all three transformations within each training fold when evaluating or
tuning a model. An outer train/test split does not protect inner tuning folds.
The [imputation guide](fitted-imputation.md#refit-inside-every-training-fold)
shows an explicit subject-fold loop. The [LASSO helper](lasso-imputation.md)
integrates mean/median or nearest-neighbor imputation and standardization within
folds. Its opt-in [`encode = TRUE` mode](lasso-encoding.md) also fits encoding
inside each training fold and reuses the saved recipe for prediction. Missing
and unknown categorical values fail explicitly. [Saved nearest-neighbor models](fitted-knn.md)
are available separately for numeric targets and mixed predictors.

## Boundaries and evidence

- Numeric columns must remain real numeric vectors and cannot contain infinity.
  Numeric missing values, singleton/constant columns, and zero-row inputs are
  allowed. No rank or identifiability guarantee is made.
- Training characters need at least two observed categories; training factors
  need at least two declared levels. Empty or entirely missing factors with a
  declared schema can be fitted. Explicit `NA` factor levels are rejected;
  ordinary missing factor values are supported.
- New categorical inputs may be factors or characters, but logical inputs must
  stay logical and numeric inputs must stay numeric. Missing categories yield
  missing values throughout their coding block. Unused new factor levels do
  not count as observed novelty.
- Names match literally, including spaces and punctuation. R's special `...`
  and `..1`-style names are unsupported. Duplicate/ambiguous input or output
  column names raise errors.
- An empty selection gives a valid empty recipe; application returns one row
  per input row and zero columns. Unselected columns do not enter the matrix.
- Encoding adds no interactions, imputation, scaling, intercept, model fitting,
  sparse output, or missing-data uncertainty assessment.

The [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-fitted-encoding.R)
fix indicator, treatment, sum, and ordered-polynomial coding values, compare
the existing matrix helper, and verify contrast-option independence,
serialization, unseen categories, missing/empty rows, literal names, held-out
perturbations, and the imputation/scaling composition. The
[inventory](method-inventory.md) records the support level and evidence scope.
