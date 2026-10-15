# Quick start

The included data are **illustrative examples**, some hand entered and some generated. They are suitable for demonstrations. See the [data guide](simulated-data.md) for provenance and design limits. These examples use only the package's required dependencies.

## Compare two groups

```r
library(PharmaStatsR)

head(pharma_sample)
test <- pharma_t_test(response ~ treatment, data = pharma_sample)
test$estimate
test$conf.int
test$p.value
```

`pharma_t_test()` returns the `stats::t.test()` result. Read the estimated difference, confidence interval, and assumptions together; a small p-value is not evidence of clinical relevance.

## Assess equivalence

Choose meaningful lower and upper bounds before examining outcomes. Here `-2` and `2` are illustrative units of response.

```r
eq <- pharma_tost(
  response ~ treatment, data = pharma_sample,
  low_eqbound = -2, high_eqbound = 2
)
eq$diff
eq$conf.int
eq$p.value
```

The difference is the first group minus the second group (factor order). At `alpha = 0.05`, the reported confidence interval is 90%. Equivalence requires both one-sided tests to reject, or equivalently that the entire interval lies strictly inside the prespecified bounds. See [Equivalence testing](equivalence.md) for limitations.

## Fit a Cox model

```r
fit <- pharma_survival_fit(
  survival::Surv(time, status) ~ treatment,
  data = pharma_survival
)
summary(fit)
```

`pharma_survival_fit()` is a wrapper around `survival::coxph()` and returns a Cox model. For a Kaplan–Meier curve with an optional log-rank test, use `pharma_kaplan_meier()`.

## Prepare covariates and fit a random-intercept model

The consolidated dataset is loaded with `data()` rather than a namespace export:

```r
data("pharmo_example", package = "PharmaStatsR")
validate_data_schema(pharmo_example)

scaled <- center_scale(pharmo_example, c("WT", "AGE", "CRCL"))
covariate_fit <- fit_covariate_model(
  scaled$data, "DV", "SubjectID", c("Time", "WT", "AGE")
)
plot_obs_vs_pred(covariate_fit, scaled$data)
plot_residuals(covariate_fit)
```

This uses an `nlme` random subject intercept and the package's required
dependencies. The simulated outcome is illustrative. The plots describe this
fit; they do not validate a pharmacokinetic model. For evaluation on held-out
data, estimate preprocessing on training data only and apply the saved scaling
parameters to the held-out data. See the [covariate guide](covariate-migration.md)
for imputation, screening, reports, apps, and the nonlinear example's limits.

The package contains [six worked vignettes](covariate-migration.md#worked-vignettes-and-evidence),
including the [original workflow](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/vignettes/pharma_workflow.Rmd).
See [installation](installation.md#worked-vignettes) to build them from GitHub.
Check [limitations](limitations.md) before applying any result to real data.
