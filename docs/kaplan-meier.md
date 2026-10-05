# Kaplan–Meier curves and log-rank comparison

`pharma_kaplan_meier()` estimates survival for a single event type and can perform an unweighted log-rank comparison between groups. It uses the same selected rows, missing-value function, and default near-tie correction for both outputs.

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

`subset` is a logical expression evaluated in `data`, with one nonmissing choice per row. It filters the data **before** either survival function evaluates the formula. `na.action` is the same function for both; the default is `stats::na.omit`. The paired analysis uses `timefix = TRUE` in both survival functions; `timefix = FALSE` is available only with `log_rank = FALSE` for curve-only analysis. Setting `log_rank = FALSE` returns only the fitted curve and allows `~ 1` for a single group.

The paired output excludes curve options such as weights, subject IDs, clusters, and `start.time` that would leave the log-rank result describing a different analysis. The helper also rejects alternative estimators and multi-state or counting-process responses; use the [survival curve](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/survfit.formula.html) and [survival comparison](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/survdiff.html) backends directly for those analyses.

## Independent numerical reference

The fixture in [test-kaplan-meier-reference.R](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-kaplan-meier-reference.R) is hand constructed, not clinical data. Each pair below is `(time, status)`, with `1` for an event and `0` for censoring. There are six independent subjects in each group and no delayed entry.

| Group | Observations |
| --- | --- |
| A | `(1, 1), (2, 1), (2, 0), (3, 1), (5, 0), (6, 1)` |
| B | `(1, 0), (2, 1), (3, 1), (3, 0), (4, 1), (6, 0)` |

At each distinct observed time, count every subject whose observed time is at least that time in the risk set. Subjects censored at an event time therefore remain at risk for the events at that time; remove both events and censorings before the next time. Let \(n_A,n_B\) denote the risk counts, \(d_A,d_B\) the events, and \(c_A,c_B\) the censorings.

| Time | \(n_A\) | \(n_B\) | \(d_A\) | \(d_B\) | \(c_A\) | \(c_B\) | \(E_{Aj}\) | \(V_{Aj}\) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 6 | 6 | 1 | 0 | 0 | 1 | 1/2 | 1/4 |
| 2 | 5 | 5 | 1 | 1 | 1 | 0 | 1 | 4/9 |
| 3 | 3 | 4 | 1 | 1 | 0 | 1 | 6/7 | 20/49 |
| 4 | 2 | 2 | 0 | 1 | 0 | 0 | 1/2 | 1/4 |
| 5 | 2 | 1 | 0 | 0 | 1 | 0 | 0 | 0 |
| 6 | 1 | 1 | 1 | 0 | 0 | 1 | 1/2 | 1/4 |

For group A, the curve's observed times are \((1,2,3,5,6)\), with survival values \((5/6,2/3,4/9,4/9,0)\). For group B, the observed times are \((1,2,3,4,6)\), with survival values \((1,4/5,3/5,3/10,3/10)\). Censor-only times do not decrease survival. Tied events at times 2 and 3 contribute jointly to the log-rank calculation.

For the ordinary two-group log-rank reference, put \(n_j=n_{Aj}+n_{Bj}\) and \(d_j=d_{Aj}+d_{Bj}\). Conditional hypergeometric event allocation gives

\[
E_{Aj}=\frac{n_{Aj}d_j}{n_j},\qquad
V_{Aj}=\frac{n_{Aj}n_{Bj}d_j(n_j-d_j)}{n_j^2(n_j-1)}
\]

for \(n_j>1\). When only one subject remains, event allocation is deterministic and its variance contribution is zero; do not evaluate a `0/0` expression. Summing the table gives

\[
O_A=4,\quad E_A=\frac{47}{14},\quad
U_A=O_A-E_A=\frac{9}{14},\quad V_A=\frac{2827}{1764}.
\]

The other group has \(O_B=3\), \(E_B=51/14\), and \(U_B=-U_A\). The full covariance and one-degree-of-freedom statistic are

\[
\operatorname{Var}(U)=V_A
\begin{pmatrix}1&-1\\-1&1\end{pmatrix},\qquad
Q=\frac{U_A^2}{V_A}=\frac{729}{2827}\approx0.2578705341.
\]

These rational targets are independent of `survfit()` and `survdiff()`. The tests compare the wrapper's risk counts, event/censor counts, curves, observed and expected totals, covariance, and statistic directly with those fixed targets, using a numerical tolerance of `1e-12` for noninteger results. The reference is arithmetic evidence, not a simulation of type-I error or a claim that the asymptotic chi-square approximation is accurate in a sample this small.

### Row selection, coding, and boundaries

The same targets are checked after adding three complete excluded rows and three selected rows missing, respectively, time, status, and group. Both `na.omit` and `na.exclude` must leave exactly the original six subjects per group; `na.fail` must reject the selected incomplete rows. The existing [option and shared-row tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-kaplan-meier.R) remain in place.

Logical status (`TRUE` for an event) and numeric 1/2 status (2 for an event) are checked against the same fixed reference, in addition to 0/1 coding. For a dataset with no observed events, use explicit logical event coding rather than relying on numeric 1/2 inference; see the [Surv event-coding documentation](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/Surv.html).

Two additional fixed boundaries are covered:

- A curve-only, all-censored sample at times `(1, 2, 2, 4)` has risk counts `(4, 3, 1)`, censor counts `(1, 2, 1)`, and survival identically one. This does not assert a meaningful log-rank comparison when there are no events.
- With A observations `(1, 0), (2, 1), (3, 1)` and B observations `(1, 1), (2, 1), (2, 0)`, the final event has only one subject at risk. Its expected A event count is one and variance contribution zero. In total, \(E_A=5/2\), \(V_A=7/12\), and \(Q=3/7\); A's curve reaches zero.

## Scope

Interpret survival curves under an appropriate independent-censoring assumption within each group and an appropriate independent-subject sampling model. The log-rank test is an unadjusted comparison; it does not adjust for baseline differences, handle clustered records, or establish proportional hazards. Use [limitations and validation](limitations.md) when planning an analysis.

The independent reference covers ordinary, unweighted, right-censored single-event data with exact ties. It does not independently validate confidence intervals, near-tie correction, stratified or weighted tests, competing events, delayed entry, or repeated records. The method remains experimental; the evidence label is not clinical validation or approval of a study-specific analysis.

## R help

Full arguments and return values: [`pharma_kaplan_meier()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_kaplan_meier.Rd). In an installed package, run `help("pharma_kaplan_meier", package = "PharmaStatsR")`.
