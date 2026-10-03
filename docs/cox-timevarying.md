# Time-varying Cox analysis

`pharma_cox_timevarying()` fits a Cox model from counting-process records. Each row gives a subject's observation interval **(start, stop]**, the covariate values that apply during that interval, and whether the event occurred at its end. A change in a covariate needs a new interval row.

```r
library(PharmaStatsR)

interval_data <- data.frame(
  id = rep(seq_len(8), each = 2),
  start = rep(c(0, 5), 8),
  stop = as.vector(rbind(rep(5, 8), 6:13)),
  status = rep(c(0, 1), 8),
  treatment = as.vector(rbind(
    c(0, 0, 1, 1, 0, 0, 1, 1),
    c(0, 1, 1, 0, 1, 0, 0, 1)
  ))
)
formula <- survival::Surv(start, stop, status) ~ treatment
fit <- pharma_cox_timevarying(formula, interval_data)
reference <- survival::coxph(formula, data = interval_data)
all.equal(unname(stats::coef(fit)), unname(stats::coef(reference)))
```

The response must be a counting-process `Surv(start, stop, status)`, with finite start and stop, `start < stop`, complete event status, and complete predictors in the selected rows. `subset` is evaluated against the **original** data before the formula and interval checks. Arguments in `...` go to `coxph()`; if they remove more rows, the wrapper errors. An ordinary `Surv(time, status)` response belongs in `pharma_survival_fit()`.

The wrapper does not verify that each subject's intervals are ordered, disjoint, or exhaustive. Inspect those records and the time origin before fitting; a person must not contribute two overlapping risk intervals at the same time. Subject IDs are not inferred by the wrapper. Supply an `id` or `cluster` argument to `coxph()` through `...` when the model and variance calculation require it, and ensure those values align with selected rows. Follow-up and covariate values must be established before the event at the interval endpoint.

The coefficient exponentiates to a model-based hazard ratio conditional on the current covariate values and proportional-hazards assumption. It does not establish that a time-varying exposure is causally assigned, that censoring is independent, or that changes in exposure were measured without bias. See the [survival package's Cox documentation](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/coxph.html) and [limitations and validation](limitations.md).
