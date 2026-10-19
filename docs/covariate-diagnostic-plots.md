# Covariate diagnostic plot values

`plot_obs_vs_pred()`, `plot_residuals()` and `plot_vpc()` return ggplot objects.
They use native model predictions or residuals and do not refit the model.
The diagnostic values must be real numeric vectors with one entry per source
row, in the same order. Matrices, lists, mismatched lengths and infinities
raise errors before a plot is returned. Missing values are allowed.

## Observed and predicted points

`plot_obs_vs_pred(model, data)` requires a numeric `DV` column and the columns
needed by the model's native `predict()` method. Each point pairs the prediction
for that row with its `DV`; the red reference line has slope one and intercept
zero. Missing coordinates remain in the plot data and are omitted when drawn.
An unrelated column named `preds` no longer replaces the calculated predictions.
The returned plot data retains the original columns for customization, with
`preds` replaced by the calculated predictions. The caller's data are unchanged.

For an `lme` model, [native prediction defaults](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/predict.lme.html)
include the fitted subject effects. Unknown subjects yield missing predictions;
the helper does not substitute population predictions. A fit made with repaired
names still needs its backend column names here. Use
[`predict_covariate_model()`](covariate-mixed-model.md) directly when choosing
population predictions or applying an original-name mapping.

## Raw and normalized residuals

`plot_residuals(model)` pairs the stored `model$data$Time` with response and
normalized residual vectors. With `lme`, these use the innermost subject level.
[Normalized residuals](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/residuals.lme.html)
account for the fitted residual scale and correlation structure; they are not
always just raw residuals divided by one common standard deviation.

Fit with `na.exclude` when excluding incomplete rows: the residual vectors then
retain missing positions for the original stored data. A fit with `na.omit`
that returns fewer residuals than stored rows now gets a clear alignment error.
The helper cannot detect an arbitrary model method that returns the right
number of values in the wrong order. Its contract relies on native row order.

The numerical reference uses four subjects with three times each:

```r
library(PharmaStatsR)
d <- data.frame(SubjectID = rep(1:4, each = 3), Time = rep(c(-1, 0, 1), 4))
u <- rep(c(-3, -1, 1, 3), each = 3)
e <- rep(c(1, -2, 1), 4)
d$DV <- 2 + 1.5 * d$Time + u + e
model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
plot_obs_vs_pred(model, d)
plot_residuals(model)
```

Within-subject residual sum of squares is 24 with seven residual degrees of
freedom; the between-subject mean square is 20. The REML components are
`24/7` for residual variance and `116/21` for random-intercept variance.
The shrinkage factor is `29/35`, giving these independent targets:

| Quantity | Reference |
| --- | --- |
| Subject prediction | `2 + 1.5 * Time + (29/35) * u` |
| Raw residual | `(6/35) * u + e` |
| Normalized residual | `((6/35) * u + e) / sqrt(24/7)` |

Tests compare both plot data and built layer coordinates with these formulas,
including shuffled rows and missing-position restoration. This reference covers
a balanced random-intercept fit with independent, constant-variance errors;
it does not establish every mixed-model residual covariance structure.

## Descriptive time bins

`plot_vpc(model, data, bins)` retains its historical name. It summarizes observed
5th, 50th and 95th percentiles and median predictions within time bins. The ribbon
is the observed distribution, without simulated predictive uncertainty. For
replicate-based bands use [`plot_simulated_vpc()`](simulated-vpc.md).

`bins` must be a positive integer. Edges are
[type-7 sample quantiles](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html)
of observed `Time` values; duplicate edges collapse. Intervals include the right
edge, and the first includes the lowest time. At least two distinct observed
times are required. An x coordinate is the mean time in its bin, rather than the
midpoint between edges. Empty bins have missing summaries.

For times `1:8`, two bins have edges `1, 4.5, 8` and mean times `2.5, 6.5`.
With observed responses `0, 10, 20, 30, 50, 60, 70, 80` and predictions
`2 + 3 * Time`, the reference summaries are:

| Mean time | Observed 5% | Observed median | Observed 95% | Predicted median |
| ---: | ---: | ---: | ---: | ---: |
| 2.5 | 1.5 | 15 | 28.5 | 9.5 |
| 6.5 | 51.5 | 65 | 78.5 | 21.5 |

The four-value type-7 percentiles interpolate at ordered positions 1.15, 2.5 and
3.85. Tests check these fixed values and all three layers, with additional
references for duplicated edges, observations exactly on a boundary, and an
affine response transformation.

Missing times never enter summaries. Within a bin, missing observed and
predicted values are removed **separately**, so the two summaries can describe
different rows. The mean time still uses all rows in that bin. All-missing
observed or predicted values produce missing summaries. These are descriptive
plots, without a model adequacy test or an assessment of selection uncertainty.

## Migration

Regenerate observed/predicted plots previously made from data containing a
`preds` column: their x coordinates could have come from that column. The binned
plot now rejects scalar or shortened predictions that previously could be
recycled. Custom model methods must provide one numeric value per source row;
select a single prediction type explicitly in your own method if it normally
returns multiple columns.

Signatures, native model defaults and valid bin calculations are unchanged.
The helpers remain experimental, with no new exports or dependencies.
