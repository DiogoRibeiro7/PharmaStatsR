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
