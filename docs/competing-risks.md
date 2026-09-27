# Competing-risks regression

`pharma_competing_risks()` fits a proportional subdistribution hazards model for a selected cause with `cmprsk::crr()`. Supply numeric event codes: one code for censoring, one for the event of interest, and distinct codes for other competing events.

```r
library(PharmaStatsR)
set.seed(11)
dat <- data.frame(
  time = rexp(150),
  status = sample(0:2, 150, replace = TRUE),
  treatment = factor(sample(c("control", "active"), 150, replace = TRUE))
)
fit <- pharma_competing_risks(
  survival::Surv(time, status) ~ treatment,
  data = dat, failcode = 1, cencode = 0
)
summary(fit)
```

| Status | Meaning in this example |
| --- | --- |
| 0 | Censored observation |
| 1 | Event of interest |
| 2 | Competing event; still used in the subdistribution model |

The `Surv(time, status)` expression identifies the two response variables. The wrapper reads the **original** status values and passes them directly to `crr()`; it does not evaluate `Surv()`. The survival package interprets numeric event codes 0, 1, and 2 as a single-event status, so extracting a constructed `Surv` response would alter the cause information. [`cmprsk::crr()`](https://cran.r-project.org/web/packages/cmprsk/refman/cmprsk.html) documents the required distinct failure and censoring codes; [`survival::Surv()`](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/Surv.html) documents its status interpretation.

## Estimand and interpretation

The fitted model for cause `k` assumes its subdistribution hazard follows

\[
h_k^*(t\mid x) = h_{0k}^*(t)\exp(x^\top\beta).
\]

For a one-unit increase in one covariate, `exp(coef(fit))` (or `exp(fit$coef)`) is a **subdistribution hazard ratio**, conditional on the model covariates. It is not a cause-specific hazard ratio. The corresponding cumulative incidence is \(F_k(t\mid x)=1-\exp[-H_{0k}^*(t)\exp(x^\top\beta)]\) under the model. Check whether proportional subdistribution hazards and the censoring assumptions suit the data before interpreting estimates.

## Inputs and limits

Formula terms are encoded with `model.matrix()`, including factor predictors and formulas without an intercept. The formula requires a two-argument, unnamed `Surv(time, status)` shape. Status codes must be numeric whole numbers; `failcode` must occur and differ from `cencode`. Time, status, and predictor variables used by the model must be complete and finite. Counting-process responses, factor status codes, and models without predictors are unsupported.

Arguments in `...` pass to `cmprsk::crr()`. For example, use its `cengroup` argument when censoring distributions differ across groups, and check that any vectors passed in `...` align with the original data rows. Results from previous versions should be recomputed because they may have misclassified event causes. See [limitations and validation](limitations.md).
