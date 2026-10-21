# Reshape time-varying covariates

`reshape_timevarying()` converts between a long table with a time column and
wide columns named `covariate_time`. It preserves measurement values and uses
explicit literal-name mappings; it does not interpolate, aggregate replicates,
or fit a model. The API remains experimental.

## Choose the observation key

Every retained column participates in the key, including the named identifier.
In long input, all columns except time and selected covariates identify a wide
row. In wide input, all columns except the selected measurement columns identify
a long group. This follows the identifier-column role in
[tidyr's wider specification](https://tidyr.tidyverse.org/reference/pivot_wider_spec.html).

A subject identifier alone need not be unique. Separate periods or replicates
can distinguish observations for the same subject. Conversely, leaving a changing
response or metadata column in the table makes it part of the key and can split
a subject across several wide rows. Select the intended key and measurement
columns before reshaping. Do not drop distinguishing information without an
explicit analysis rule.

Keys must be unique in wide input and key/time combinations must be unique in
long input. Repeated keys now fail in either direction, even if measurement
values agree or are all missing. Missing key values are allowed and count as
equal for duplicate detection; the function does not validate subject identity.

```r
library(PharmaStatsR)

wide <- data.frame(id = c(1L, 1L), WT_0 = c(70, 80))
# reshape_timevarying(wide, "WT", "id")
# Error: Duplicate wide row keys cannot be reshaped uniquely; check retained columns

wide$replicate <- c(1L, 2L)
reshape_timevarying(wide, "WT", "id")
#   id replicate Time WT
# 1  1         1    0 70
# 2  1         2    0 80
```

An explicit replicate column is appropriate only when the records represent
separate replicates. For accidental duplicates, reconcile the source records;
the helper never chooses a value, averages records, or discards a duplicate.
Previous wide inputs with repeated keys now require that decision before use.

## Missing cells and ordering

This fixed example starts with interleaved subjects and an absent observation:

```r
long <- data.frame(id = c(2L, 1L, 2L), Time = c(1L, 0L, 0L), WT = c(72, 60, 70))
wide <- reshape_timevarying(long, "WT", "id")
as.data.frame(wide)
#   id WT_1 WT_0
# 1  2   72   70
# 2  1   NA   60

reshape_timevarying(wide, "WT", "id")
#   id Time WT
# 1  2    1 72
# 2  2    0 70
# 3  1    1 NA
# 4  1    0 60
```

The absent `(id = 1, Time = 1)` becomes an explicit missing row. An existing row
with missing measurements is retained too. No provenance flag distinguishes
structural missingness from an originally recorded missing value. When different
covariates have different sets of wide time columns, conversion uses their union
of labels and fills absent cells with missing values. A round trip may therefore
add rows or all-missing wide columns.

Wide rows follow keys' first appearance. Wide measurement columns follow the
selected covariate order, then the first appearance of times for each covariate.
Long output groups times within each original wide row. Its time and value-column
order follow first appearance in the wide column names, even if the selection
vector uses a different order. This uses the default row ordering of
[tidyr's longer specification](https://tidyr.tidyverse.org/reference/pivot_longer_spec.html).
No chronological sorting or restoration of original interleaved rows occurs.

## Names, types, and limits

Covariate prefixes and time suffixes are literal: spaces, punctuation, and
underscores are supported. Overlapping prefixes, empty suffixes, output-name
collisions, and ambiguous retained measurement-like names raise errors. The
identifier is retained even when its name starts with a selected prefix.

Long time values must be nonmissing, nonempty atomic values. Distinct values
must produce distinct wide labels. On conversion back, labels become numeric
only when conversion does not introduce missing values or collapse distinct
labels; for example, `01` and `1` together remain character. Original time
classes, formatting, and row names are not saved. Empty wide tables can retain
a schema through their column names; empty long tables have no time mapping
and are rejected.

Compatible measurement types are combined using tidyr's type rules. The fixed
references cover numeric, integer, logical and ordered-factor measurements,
including unused factor levels and Date-valued retained metadata. They do not
establish arbitrary custom-class compatibility or round-trip byte identity.
Reshaping does not handle interpolation, imputation uncertainty, within-subject
correlation, or subject-grouped validation splits.

The [fixed-table references](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-timevarying-reference.R)
spell out expected values, classes, row/column order and sparse completion
without computing expected outputs through another pivot. Existing
[name and input checks](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-timevarying.R)
cover literal labels and ambiguity. The [inventory](method-inventory.md) records
the experimental support level.
