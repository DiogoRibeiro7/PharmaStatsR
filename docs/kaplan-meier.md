# Kaplan–Meier curves and log-rank comparison

`pharma_kaplan_meier()` estimates survival for a single event type and can perform an unweighted log-rank comparison between groups. It uses the same selected rows, missing-value function, and time-rounding option for both outputs.

```r
library(PharmaStatsR)

result <- pharma_kaplan_meier(
  survival::Surv(time, status) ~ treatment,
  data = pharma_survival,
  conf.type = "log-log"
)
plot(result$fit, xlab = "Time", ylab = "Estimated survival")
result$test$chisq
```

The estimate at event time \(t\) is \(\widehat S(t)=\prod_{t_j\leq t}(1-d_j/n_j)\), where \(d_j\) is the number of events and \(n_j\) the number at risk just before time \(t_j\). The ordinary log-rank test compares observed and expected events under the null of equal survival curves. Its chi-square statistic alone is not an effect estimate or a hazard ratio.

## Options and common data

Use `conf.type` and `conf.int` in `...` for curve intervals. Those options go to `survival::survfit()`, **not** `survival::survdiff()`:

```r
result <- pharma_kaplan_meier(
  survival::Surv(time, status) ~ treatment,
  data = pharma_survival,
  subset = time >= 5,
  na.action = stats::na.exclude,
  conf.type = "log-log",
  conf.int = 0.9
)
```

`subset` is a logical expression evaluated in `data`, with one nonmissing choice per row. It filters the data **before** either survival function evaluates the formula. `na.action` is the same function for both; the default is `stats::na.omit`. `timefix` is forwarded to both. Setting `log_rank = FALSE` returns only the fitted curve and allows `~ 1` for a single group.

The paired output excludes curve options such as weights, subject IDs, clusters, and `start.time` that would leave the log-rank result describing a different analysis. The helper also rejects alternative estimators and multi-state or counting-process responses; use the [survival curve](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/survfit.formula.html) and [survival comparison](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/survdiff.html) backends directly for those analyses.

## Scope

Interpret survival curves under an appropriate independent-censoring assumption. The log-rank test is an unadjusted comparison; it does not adjust for baseline differences, handle clustered records, or establish proportional hazards. Use [limitations and validation](limitations.md) when planning an analysis.
