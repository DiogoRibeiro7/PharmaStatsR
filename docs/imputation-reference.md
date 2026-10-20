# Numeric imputation reference

Numeric imputation replaces each missing target with a location estimate.
`impute_mean()` and `impute_median()` estimate from the supplied table;
`fit_imputation()` saves training estimates for `apply_imputation()`.
`impute_ml()` and `apply_knn_imputation()` average the selected numeric donors.
The latter uses only the donors saved by `fit_knn_imputation()`.

## Fixed arithmetic references

For observed values `1, 3, 8`, the arithmetic mean is `12 / 3 = 4` and the
median is `3`. For `-2, 2, 6, 10`, the mean is `16 / 4 = 4` and the median is
the average of the central pair `(2, 6)`, also `4`. Missing values do not enter
the denominator or the sorted observations. See R's definitions of
[mean](https://stat.ethz.ch/R-manual/R-devel/library/base/html/mean.html) and
[median](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/median.html).

```r
library(PharmaStatsR)
training <- data.frame(x = c(1, NA, 3, 8, NaN))
impute_mean(training, "x")$x   # 1, 4, 3, 8, 4
impute_median(training, "x")$x # 1, 3, 3, 8, 3
params <- fit_imputation(training, "x")
apply_imputation(data.frame(x = c(NA, 100)), params)$x # 4, 100
```

The independent tests check these targets in ordinary, large and small units,
with both signs, literal column names, row identity, and unchanged observed
values. Ratios remove the unit before comparison, so an incorrect zero cannot
pass an absolute tolerance merely because the expected answer is tiny.

## Extreme finite values

A finite-data mean is mathematically bounded by the observed extremes, but
intermediate arithmetic can overflow. For example, the five values
`c(-1.5, 1.5, 1.5, 1.5, 1.5) * 1e308` have mean `0.9e308` and median `1.5e308`.
On some platforms, correction terms in the direct mean calculation overflow.

The numeric preprocessing paths now retain a finite direct mean unchanged.
Only a non-finite result for nonempty finite observations triggers a fallback:
divide by the largest absolute observation, calculate the mean in those units,
and multiply back. This calculation is shared with `center_scale()`.
Median calculations are unchanged.

The fallback applies to:

- means estimated by `impute_mean()` and `fit_imputation(method = "mean")`;
- selected numeric donor means in `impute_ml()` and `apply_knn_imputation()`;
- internal missing-predictor means for legacy Euclidean `impute_ml()`;
- the mean already protected by the [scaling fallback](scaling-reference.md).

For the five-value example, three tied nearest donors in original row order
have mean `0.5e308`; all five have mean `0.9e308`. The tests check both signs,
`k = 3`, `k = 5`, and `k` larger than the donor count. Predictor weights govern
selection, not averaging. They do not weight the selected target values.

A separate predictor-fill reference uses
`x = c(-1.5, 1.5, 1.5, 1.5, 1.5, NA, 0) * 1e308` and
`y = c(10, 20, 30, 40, 50, 60, NA)`. The six observed `x` values average
`0.75e308`. Euclidean filling makes donor 6 closest to recipient `x = 0`,
so `k = 1` fills `y` with `60`. Gower omits donor 6's missing pair; the other
distances tie and original donor 1 supplies `10`. Filling is internal: the
caller's missing `x` remains missing.

## Reuse, migration and limits

Earlier versions could reject finite location estimates, write a non-finite
neighbor replacement, or fail distance calculation after predictor filling.
Affected imputations should be recomputed. Existing saved parameter/model
structures remain valid; there are no new arguments, exports or dependencies.
Ordinary finite means, categorical modes, tie order, distance definitions and
all-missing policies are retained. Euclidean distances that are themselves
unrepresentable still raise an error requesting rescaling.

`NA` and `NaN` are filled, while observed target values are preserved. An
entirely missing location target stays missing with a warning in the legacy
helpers; fitting reusable parameters rejects it. Saved location estimates and
neighbor models can be restored with RDS. New observed rows do not become donors
or change another row's replacement when using the saved apply functions.

This is a targeted overflow fallback. Finite direct means can still have limited
precision, very small results can round to zero, and differences lost before
the call cannot be recovered. No arbitrary-precision result is promised.
These single-value replacements do not quantify missing-data uncertainty.

Fit on training rows and refit inside validation folds. The
[training-preprocessing guide](fitted-imputation.md) and
[saved neighbor guide](fitted-knn.md) describe that separation. Legacy helpers
still use the supplied table; the mean fallback does not prevent data leakage.
The [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-imputation-reference.R)
cover these fixed targets, saved restoration, batch independence and boundaries.
All these APIs remain experimental.
