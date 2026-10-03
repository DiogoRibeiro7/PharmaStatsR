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

For another example, see the [workflow vignette](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/vignettes/pharma_workflow.Rmd) and the installed R help pages. Check [limitations](limitations.md) before applying any result to real data.
