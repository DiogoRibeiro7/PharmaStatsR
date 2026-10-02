# Model diagnostics

`pharma_model_diagnostics()` reports residuals, standardized residuals, Cook's distance, leverage, and a screening flag for each observation available from a fitted univariate `lm` or `glm`.

```r
library(PharmaStatsR)

fit <- lm(response ~ treatment, data = pharma_sample)
diagnostics <- pharma_model_diagnostics(fit)
head(diagnostics)
subset(diagnostics, flag %in% TRUE)
```

## Measures and cutoffs

| Output | Meaning |
| --- | --- |
| `residual` | The fitted model's default residual: ordinary for `lm`, deviance for `glm`. |
| `std_resid` | `stats::rstandard(fit)`: standardized residuals (Pearson by default for `glm`). |
| `cook_d` | `stats::cooks.distance(fit)`: change in fitted model associated with deleting one observation. |
| `leverage` | `stats::hatvalues(fit)`: diagonal of the model's hat matrix. |
| `flag` | `abs(std_resid) > threshold` or `cook_d > cook_cutoff`. |

The default residual threshold is 3 and the default Cook cutoff is \(4/n_{\mathrm{fit}}\), with \(n_{\mathrm{fit}}=\texttt{stats::nobs(fit)}\). Change the Cook rule if a different descriptive screen is appropriate:

```r
pharma_model_diagnostics(fit, threshold = 2.5, cook_cutoff = 0.5)
```

Both cutoffs must be finite positive scalars. If the model used `na.exclude`, R can restore excluded positions as missing diagnostic values; their flags remain `NA`. The fitted observation count excludes these rows. [R's regression diagnostics](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/influence.measures.html) define the measures, and [`nobs()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/nobs.html) counts observations used in the fit.

## Interpreting a flag

A `TRUE` flag means that at least one screening cutoff was exceeded. It does not prove a data error, justify removing that row, or validate the fitted model. Inspect the original observation, fit assumptions, and sensitivity of the result before deciding whether any change is warranted. Standardized and Cook diagnostics for `glm` are approximations, especially when points are highly influential. A multivariate `lm` does not have one scalar diagnostic per row and is rejected.
