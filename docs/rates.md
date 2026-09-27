# Event-rate comparisons

`pharma_rate_metrics()` compares **independent groups** with a binary endpoint. Supply the number of participants with an event and the total in each group. Group 1 is the numerator of the risk ratio and the first term in the difference.

```r
library(PharmaStatsR)

out <- pharma_rate_metrics(event1 = 10, n1 = 100,
                           event2 = 15, n2 = 110)
out$risk_difference
out$rd_ci
out$risk_ratio
out$rr_ci
```

## Estimates and intervals

| Output | Calculation | Interpretation |
| --- | --- | --- |
| `risk_difference` | \(\hat p_1-\hat p_2\), where \(\hat p_i=e_i/n_i\) | Absolute event-probability difference; positive means a higher event rate in group 1. |
| `rd_ci` | Two-sided Newcombe interval without continuity correction, combining each group's Wilson score interval | Approximate uncertainty for the difference; endpoints remain within −1 and 1. |
| `risk_ratio` | \(\hat p_1/\hat p_2\) | Relative event probability when the denominator is nonzero. |
| `rr_ci` | Two-sided log-Wald interval after adding 0.5 to **each of the four cells** (events and non-events in each group) | Approximate uncertainty for the ratio, including zero-event groups. |

For the ratio interval, the adjusted event risk in group \(i\) is \((e_i+0.5)/(n_i+1)\). Its log standard error is

\[
\sqrt{\frac{1}{e_1+0.5}-\frac{1}{n_1+1}
      +\frac{1}{e_2+0.5}-\frac{1}{n_2+1}}.
\]

The **point estimates use the original counts**. Adding 0.5 applies only to the ratio interval, so its center generally differs from the reported point estimate. The risk difference interval uses the unadjusted observed proportions.

## Zero events and all events

```r
pharma_rate_metrics(0, 12, 0, 15)
pharma_rate_metrics(5, 12, 0, 15)
pharma_rate_metrics(8, 8, 12, 12)
```

When neither group has events, the risk difference is zero, the ratio point estimate is `NA` (0/0 is undefined), and both intervals have positive width. When only group 2 has zero events, the ratio point estimate is `Inf`; when only group 1 has zero events, it is zero. In both cases, the adjusted ratio interval is finite. Extreme counts can still produce very wide and asymmetric ratio intervals; the half-count is a convention, not evidence of half an observed event.

This replaces the earlier Wald difference interval and unadjusted log ratio interval. **Recompute previously reported intervals.** Count inputs must be single finite whole numbers, sample sizes positive, events no greater than sample sizes, and `conf.level` strictly between zero and one.

## Assumptions and scope

These are **approximate, unadjusted comparisons** of independent binomial groups. They do not adjust for covariates, exposure time, clustering, repeated observations, censoring, multiplicity, or a study-specific estimand. The ratio interval can have poor coverage in small or extreme samples, and a continuity correction can materially affect it. Check that the endpoint and group order match the analysis plan, and independently validate important results before use in a study.

The risk-difference construction follows [Newcombe's comparison of interval methods](https://pubmed.ncbi.nlm.nih.gov/9595617/). See [limitations and validation](limitations.md) for project-wide constraints.
