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

## One-table design checks

`prepare_model_matrix()` uses the supplied table and current contrast settings.
The selected covariate order determines which categorical term gets full
indicator coding in the additive, no-intercept design. Subsequent categorical
terms use their factor attributes or active contrast options. Numeric values,
row names, row order, and R's `assign` and `contrasts` attributes are preserved.
`assign` maps each expanded column back to its selected covariate.

The [independent design references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-design-reference.R)
fix the following values without using `model.matrix()` to calculate expected
answers. Here `group` is the first categorical term and `stage` is a later
ordered factor with levels `low`, `mid`, `high`:

| Input | Expected coding |
| --- | --- |
| `group = A, B, C` | Indicator rows `(1, 0, 0)`, `(0, 1, 0)`, `(0, 0, 1)` |
| Later three-level factor, treatment contrasts | Rows `(0, 0)`, `(1, 0)`, `(0, 1)` |
| Later three-level factor, sum contrasts | Rows `(1, 0)`, `(0, 1)`, `(-1, -1)` |
| `stage = low, mid, high` | Linear column `(-1, 0, 1) / sqrt(2)` and quadratic column `(1, -2, 1) / sqrt(6)` |
| Later logical term `FALSE, TRUE` | One column `(0, 1)` under treatment contrasts |

For three rows with `x = 1, 2, 3`, `group = A, B, C`,
`stage = low, mid, high`, and `flag = FALSE, TRUE, FALSE`, coefficients
`(2, 10, 20, 30, sqrt(2), sqrt(6), 5)` for the ordered columns
`x, groupA, groupB, groupC, stage.L, stage.Q, flagTRUE` yield predictions
`12, 27, 38`. The tests also cover reordered covariates and rows, custom contrast
matrices, logical full indicators, unused levels, and missing/empty rows.

Expanded column names must be unique. For example, selecting factor `group`
with level `A` together with a numeric column named `groupA` would create two
columns named `groupA`; this now raises an error. Rename the conflicting input
or level explicitly and rebuild the design. Names are not silently repaired.

Generated coding must be finite wherever its own covariate is observed.
Invalid custom contrasts raise an error naming that covariate, even when a
different variable is missing in the same row. Numeric `NA`/`NaN` and missing
categorical blocks remain allowed; global `na.action` settings do not drop rows.
These one-table checks examine coding emitted for supplied rows: an invalid
contrast for an unused category can remain undetected. `fit_encoding()` probes
all declared levels before saving its coding. Correct non-finite contrast values
and rebuild any affected design or recipe.

Finite coding and unique labels do not imply full rank or identifiable effects.
The helper does not save training settings; use `fit_encoding()` and
`apply_encoding()` when later batches must retain training levels and coding.
Neither workflow chooses a scientific contrast or a train/test split for you.

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
