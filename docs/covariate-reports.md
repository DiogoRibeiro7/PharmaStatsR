# Covariate model reports

`generate_report()` renders a fixed-effects table and two diagnostic plots from
a native `nlme::lme` fit. HTML needs `rmarkdown`, `knitr`, and Pandoc; PDF also
needs LaTeX. The report is an experimental summary of a fitted analysis.

For an interactive console summary, use `summary(model)` and
`coef(summary(model))`. The [model summary guide](model-summaries.md) explains
the shared R workflow and the statistics each model supplies.

## Render a reproducible example

```r
library(PharmaStatsR)

d <- data.frame(SubjectID = rep(1:4, each = 3), Time = rep(c(-1, 0, 1), 4))
d$DV <- 2 + 1.5 * d$Time + rep(c(-3, -1, 1, 3), each = 3) +
  rep(c(1, -2, 1), 4)
model <- fit_covariate_model(d, "DV", "SubjectID", "Time")

html <- generate_report(model, d, output_file = "reports/analysis.html")
# With LaTeX installed:
# pdf <- generate_report(model, d, "pdf_document", "reports/analysis.pdf")
```

The returned string is the absolute path to the rendered file. Relative paths
start from the caller's working directory, missing parent directories are
created, and an omitted extension is supplied by the renderer. Existing output
files may be overwritten. The installed template is copied to a temporary
workspace, which is removed on success or failure; the caller's working
directory and installed template are preserved.

## A consistent fixed-effects table

The table always uses `summary(model)$tTable`. Its rows and columns no longer
depend on whether `broom.mixed` is installed, and that unused optional suggestion
has been removed. Reports now consistently show:

| Column | Meaning |
| --- | --- |
| Term | Native fitted coefficient label |
| Estimate | Fixed-effect coefficient |
| Std. Error | Native approximate standard error |
| DF | Native denominator degrees of freedom |
| t statistic | Estimate divided by its standard error |
| p value | Native two-sided t-test p-value |

[The nlme summary documentation](https://stat.ethz.ch/R-manual/R-patched/library/nlme/html/summary.lme.html)
describes these values and its default sigma adjustment for maximum-likelihood
fits. The report retains those defaults and does not refit the model. The
example above uses REML. Denominator degrees of freedom are the backend's
convention, not a new inferential method introduced by the report.

Values are displayed with six significant digits and a decimal point. P-values
below `1e-6` appear as `<1e-6`, including values that underflowed to zero in the
backend. Obtain full precision from `summary(model)$tTable`; the output file is
not a numeric interchange format. Coefficient names are escaped for the selected
HTML or LaTeX table format, so labels such as `group<b>&H</b>` remain text.

The table contains fixed effects only. Random-effect and residual variance rows
previously appeared in some installations through the optional tidier. Use
`nlme::VarCorr(model)` separately for those estimates. Regenerate reports if
consistent columns, variance-row scope, or escaped labels matter to a comparison.
The file paths and public function arguments are unchanged.

## Independent numerical reference

The balanced example has four subjects with deviations `(-3, -1, 1, 3)` and
three times `(-1, 0, 1)`. The within-subject error pattern is `(1, -2, 1)`.
The fixed coefficients are `(2, 1.5)`. Within-subject residual sum of squares is
`24` with `7` residual degrees of freedom; the between-subject mean square is
`20`. Thus the REML variance targets are `sigma^2 = 24/7` and
`tau^2 = (20 - 24/7)/3 = 116/21`.

For the balanced design, the intercept variance is
`(tau^2 + sigma^2/3)/4 = 5/3`; the time-slope variance is
`sigma^2 / sum(Time^2) = (24/7)/8 = 3/7`.

| Term | Estimate | Standard-error target | Denominator DF in this design |
| --- | --- | --- | --- |
| `(Intercept)` | 2 | `sqrt(5/3)` | 7 |
| `Time` | 1.5 | `sqrt(3/7)` | 7 |

For each row, `t = estimate / SE` and `p = 2 * pt(-abs(t), df = 7)`.
The [rendered-value tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-report-reference.R)
parse the actual HTML table and compare against these targets with tolerance
for display rounding and variance optimization. They repeat the check after
row permutation and saved-model restoration, and after replacing the response
by `7 - 2 * DV` (coefficients become `(3, -3)` and standard errors double).
Additional cases cover small p-values and literal HTML-like factor labels,
including PDF rendering when LaTeX is available. Existing
[path and rendering tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-report.R)
cover relative/absolute destinations, temporary-workspace cleanup and render
failures. This evidence does not establish every model structure or custom class.

## Diagnostic and interpretation limits

The supplied `data` must contain numeric `DV` and the native model's prediction
columns. It controls the observed/predicted plot; it does not determine the
coefficient table or refit the model. Predictions use native defaults, including
subject effects for known subjects. The residual plot uses numeric `Time` in
`model$data` and its stored row order. Residual vectors must align with those
rows; fit with `na.exclude` when rows are omitted. See the
[diagnostic plot guide](covariate-diagnostic-plots.md) for precise boundaries.

The report does not automatically apply `repair_names = TRUE` mappings or infer
arbitrary response/time names. Its `DV`/`Time` requirements still apply. For
original-name prediction from mapped fits, use the
[mixed-model prediction workflow](covariate-mixed-model.md) separately.
The report contains no confidence intervals, multiplicity or post-selection
adjustments, model-adequacy decision, simulation-based predictive uncertainty,
or clinical/regulatory validation. A rendered document does not establish that
the selected model or inference is appropriate for a study.
