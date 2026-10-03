# Meta-analysis model choice

`pharma_meta_analysis()` delegates a specified model to `metafor::rma()`. The default `method = "REML"` estimates between-study heterogeneity for a random-effects model. Choose `method = "FE"` explicitly for a fixed-effects model. A failed REML fit now returns the backend error; it does not retry as FE.

```r
library(PharmaStatsR)

yi <- c(-0.5, 0.1, 0.8, 1.4, 1.8)
vi <- c(0.04, 0.05, 0.03, 0.06, 0.05)

random_fit <- pharma_meta_analysis(yi, vi)             # REML
fixed_fit <- pharma_meta_analysis(yi, vi, method = "FE") # Explicit model
summary(random_fit)
summary(fixed_fit)
```

Here `vi` contains **sampling variances**, not standard errors. For the FE fit, inverse-variance weights are \(w_i=1/v_i\), so \(\hat\mu=\sum_i w_i y_i/\sum_i w_i=0.6565217391\) and its standard error is \((\sum_i w_i)^{-1/2}=0.0932504808\). [The tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-meta-analysis.R) pin these values, compare FE and REML outputs with direct `metafor::rma()` calls, and check that a singular backend error causes only one attempted fit.

## Analysis contract

- `yi` and `vi` are finite numeric vectors of equal length. The default is REML; pass `method = "FE"` only when that model is intended. Other valid estimator names and further model options come from [`metafor::rma()`](https://wviechtb.github.io/metafor/reference/rma.uni.html). The backend is optional and must be installed to run the helper.
- Errors during estimation propagate to the caller. Inspect the original error and the data before changing models; an FE estimate after a failed REML fit answers a different modelling question and should be an explicit analysis decision. A boundary estimate \(\tau^2=0\) from a successful random-effects fit is still a successful fit with the requested method.
- The wrapper does not verify that effect sizes share a measure, that studies are independent, or that heterogeneity assumptions suit the evidence. Examine the input effect-size definitions and model diagnostics for a real synthesis. In `metafor`, "FE" and "EE" can yield identical numerical estimates but have different interpretations; specify the intended model in the analysis plan.

Earlier calls that printed an FE fallback message after a singular REML error returned a different model from the one requested. Recheck those results and rerun an explicitly chosen method. See [limitations](limitations.md) and the [method inventory](method-inventory.md) for the package's review scope.

## Forest and funnel plots

`pharma_forest_plot()` and `pharma_funnel_plot()` require the optional
`metafor` package and an `rma` model. They delegate to `metafor::forest()`
and `metafor::funnel()`, drawing base graphics on the active device. They do
not return a reusable plot object. The forest helper invisibly returns a list
of plotting parameters, including axis limits; the funnel helper invisibly
returns a data frame with plotted coordinates and study labels. Assign these
results only when you need that metadata.

```r
pharma_forest_plot(random_fit, slab = paste("Study", seq_along(yi)))
pharma_funnel_plot(random_fit)
```

The [forest](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_forest_plot.Rd)
and [funnel](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_funnel_plot.Rd)
R help pages describe the arguments and return values. The wrappers check
the `rma` class and a missing backend; the [plot smoke tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-pharma_tests.R)
exercise drawing with `metafor` installed. A funnel's appearance alone does
not establish publication bias or rule it out, especially with a small set
of studies. Review the underlying studies and effect measures before drawing
an inference from either plot.

## Moderator models

`pharma_meta_regression()` fits a meta-regression with `metafor::rma()`.
Pass a numeric moderator matrix with one row per effect size, or a one-sided
formula with its study-level variables in `data`. The wrapper checks matrix
shape and finite values, but it cannot establish whether study outcomes and
moderators are correctly aligned.

```r
studies <- data.frame(dose = 1:6)
yi <- c(-0.3, 0.2, 0.4, 0.1, 0.7, 0.9)
vi <- c(0.06, 0.04, 0.05, 0.03, 0.08, 0.04)

mixed_fit <- pharma_meta_regression(yi, vi, mods = ~ dose, data = studies)
fixed_fit <- pharma_meta_regression(yi, vi, mods = ~ dose,
                                    data = studies, method = "FE")
summary(mixed_fit)
```

The default `method = "REML"` estimates residual between-study heterogeneity;
`method = "FE"` fits a fixed-effects moderator model. With the default
intercept and inverse-variance weights, the FE coefficients solve
\(\hat\beta=(X^\top W X)^{-1}X^\top W y\), where \(W\) has diagonal entries
\(1/v_i\). The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-meta-regression.R)
check this result independently and compare the formula path to `metafor`.
Coefficients describe study-level associations under the chosen model. They
do not identify an individual-level dose effect or a causal relationship;
check confounding, outcome definitions, residual heterogeneity, and the
limited number of studies before interpretation. The backend error is returned
if the requested model cannot be fitted.

## R help

Full arguments and return values:

- [`pharma_meta_analysis()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_meta_analysis.Rd)
- [`pharma_meta_regression()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_meta_regression.Rd)

In an installed package, run `help(package = "PharmaStatsR")` to open the corresponding topics.
