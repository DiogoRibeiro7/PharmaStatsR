# Centering and scaling reference

`center_scale(data, vars)` estimates a mean and sample standard deviation for
each selected numeric column, returning transformed data and a `params` table.
`apply_center_scale(newdata, params)` reuses those estimates by literal column
name. It does not estimate anything from the new batch.

## Arithmetic and missing values

For the `n` observed values of a column, the transformation is

\[
\bar{x}=\frac{1}{n}\sum_i x_i,\qquad
s=\sqrt{\frac{\sum_i(x_i-\bar{x})^2}{n-1}},\qquad
z_i=\frac{x_i-\bar{x}}{s}.
\]

The divisor is the observed count minus one, as in
[R's sample standard deviation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/sd.html).
`NA` and `NaN` do not contribute to estimates and retain their missing positions.
Different columns can use different observed rows. At least two observed values
and a positive, finite scale are required for training. Constant columns and
infinite inputs are rejected; an empty selection preserves the table.

For observed values `1, 2, 4, 5`, the mean is `3`, centered sum of squares is
`10`, and sample SD is `sqrt(10/3)`. The standardized values are
`c(-2, -1, 1, 2) / sqrt(10/3)`. For `-2, 0, 2`, the mean is zero and sample SD
is two. These fixed targets are checked independently, with literal names,
missing entries, column/row preservation and negative changes of units.

```r
library(PharmaStatsR)
training <- data.frame(x = c(1, 2, 4, 5, NA_real_))
fitted <- center_scale(training, "x")
fitted$params
apply_center_scale(data.frame(x = c(7, NA_real_)), fitted$params)
# x: 4 / sqrt(10/3), NA
```

## Extreme numeric units

A standard deviation can be representable even when its squared variance is
not. For example, `c(1, 2, 3) * 1e200` has sample SD `1e200`, while the variance
exceeds the floating-point range. At `1e-200`, the variance can round to zero.
Both cases now return standardized values near `-1, 0, 1`.

The ordinary positive finite SD result is retained. Only a zero or non-finite
result triggers the fallback: center the observed values, normalize by their
largest absolute magnitude, compute SD in those units, and restore the units.
If centering itself overflows, normalize the original observed values instead.
Centering first where possible avoids losing small differences at large offsets.
If the direct mean is non-finite, it is recomputed after normalizing the
original values by their largest absolute magnitude. This also avoids overflow
in mean correction on platforms without a wider internal accumulator. Finite
direct means are retained.

Training transformations then use `apply_center_scale()`'s existing arithmetic,
which can divide before subtracting when direct subtraction overflows.

The tests include these independent targets:

| Input, before multiplying by unit | Unit | Mean / unit | SD / unit | Standardized values |
| --- | --- | ---: | --- | --- |
| `1, 2, 4, 5` | `1e200` or `1e-200` | 3 | `sqrt(10/3)` | `c(-2,-1,1,2)/sqrt(10/3)` |
| `-1.5, 1.5, 1.5, 1.5, 1.5` | `1e308` | 0.9 | `3/sqrt(5)` | `c(-4,1,1,1,1)/sqrt(5)` |

The second case also overflows direct subtraction for the negative value.
Both signs and reordered rows are checked across Windows, Linux and macOS.
The tests compare scale estimates **after dividing out the unit**, so an
incorrect zero cannot pass merely because the expected scale is tiny.

A separate binary-offset case uses `2^600 + c(0,1,2,4) * 2^548`.
Its exact mean is 1.75 steps above the offset, but the stored double-precision
mean rounds to two steps. The sample SD is `sqrt(35/12)` steps. The resulting
values follow the stored rounded mean and need not have an exactly zero mean.
This distinction is checked explicitly rather than hidden by a loose tolerance.

## Reuse and limits

Save `fitted$params` with `saveRDS()` and apply it after `readRDS()`. Training
and saved-parameter application use the same transformation path. New batches
may be empty, singleton, constant or entirely missing because they do not need
to estimate a scale. Adding unrelated prediction rows cannot change an existing
row's transformation. Row/column order, row names and unselected columns remain
available; the caller's data and saved parameter table are not modified.

Fit on training rows, then apply to validation rows. For tuning procedures,
refit within each training fold; see the [preprocessing guide](fitted-imputation.md).
These single transformations do not quantify missing-data uncertainty or remove
outliers, and they do not add preprocessing to an existing model automatically.

Floating-point limits still apply. The fallback cannot recover distinctions
already rounded away in the input, and a positive finite direct SD may still
have limited precision. Truly unrepresentable SDs still fail, as do transformed
values outside the numeric range. This is a targeted fallback, not arbitrary-
precision arithmetic or a guarantee of exact unit invariance at every scale.

## Migration

Earlier versions rejected some extreme-unit columns despite representable
means and SDs. They can now be fitted and reused. Ordinary positive finite
estimates, function signatures and return structures are unchanged. Existing
saved parameter tables remain usable. There are no new exports or dependencies;
both helpers remain experimental.
