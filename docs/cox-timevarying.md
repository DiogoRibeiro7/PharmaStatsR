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

## Independent counting-process reference

The hand-constructed fixture in [test-cox-counting-reference.R](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-cox-counting-reference.R) has six subjects, eight interval records, five events, and one binary covariate `exposure`. Each subject has at most one event. Times and exposure are illustrative, not clinical observations.

| Row | Subject | Start | Stop | Event | Exposure |
| --- | --- | --- | --- | --- | --- |
| A1 | A | 0 | 2 | 1 | 1 |
| B1 | B | 0 | 2 | 0 | 0 |
| B2 | B | 2 | 4 | 1 | 1 |
| C1 | C | 0 | 3 | 1 | 0 |
| D1 | D | 0 | 5 | 1 | 0 |
| E1 | E | 0 | 4 | 0 | 1 |
| E2 | E | 4 | 6 | 1 | 0 |
| F1 | F | 2 | 7 | 0 | 1 |

B changes from zero to one after time 2, and E changes from one to zero after time 4. F enters after time 2 and is censored at time 7. An intermediate row's `event = 0` marks an interval ending without an event; B1 and E1 do not terminate their subjects' follow-up.

### Risk sets and endpoint conventions

An interval contributes at event time \(t\) precisely when \(\mathrm{start}<t\leq\mathrm{stop}\), as specified in the [official Surv documentation](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/Surv.html). Consequently, B1, not B2, applies at the event at time 2, and F is not yet at risk. At the event at time 4, E1 still applies. The interval labels make these choices independently reviewable:

| Event time | Eligible intervals | \(n_0\) | \(n_1\) | Event subject | Event exposure \(x_j\) |
| --- | --- | --- | --- | --- | --- |
| 2 | A1, B1, C1, D1, E1 | 3 | 2 | A | 1 |
| 3 | B2, C1, D1, E1, F1 | 2 | 3 | C | 0 |
| 4 | B2, D1, E1, F1 | 1 | 3 | B | 1 |
| 5 | D1, E2, F1 | 2 | 1 | D | 0 |
| 6 | E2, F1 | 1 | 1 | E | 0 |

Here \(n_0,n_1\) count subjects with current exposure zero and one. No subject contributes two rows to the same risk set. The five event times are distinct: an interval boundary coinciding with an event is not a tie between two events.

Fit the fixture with `ties = "breslow"`, `robust = FALSE`, and `init = 0`. This fixes the tie and variance conventions and the initial likelihood evaluation. No weights, clustering, strata, or subject-ID argument are passed. IDs are retained separately in the fixture to audit subject histories and counts; the returned `n` counts interval rows, not independent subjects. The [Cox backend documentation](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/coxph.html) describes the model-based versus robust variance options.

### Partial likelihood, score, and information

Let \(r=\exp(\beta)\). With one event at each time, the partial log likelihood is

\[
\ell(\beta)=\sum_{j=1}^{5}\{x_j\beta-\log(n_{0j}+n_{1j}r)\}
=2\beta-\log(3+2r)-\log(2+3r)-\log(1+3r)
-\log(2+r)-\log(1+r).
\]

The score \(U=\ell'\) and observed information \(I=-\ell''\) are

\[
U(\beta)=2-\frac{2r}{3+2r}-\frac{3r}{2+3r}-\frac{3r}{1+3r}
-\frac{r}{2+r}-\frac{r}{1+r},
\]

\[
I(\beta)=\frac{6r}{(3+2r)^2}+\frac{6r}{(2+3r)^2}
+\frac{3r}{(1+3r)^2}+\frac{2r}{(2+r)^2}
+\frac{r}{(1+r)^2}.
\]

Information is strictly positive for finite \(\beta\). The score decreases from 2 to -3 as \(\beta\) increases from negative to positive infinity, giving one finite maximum. Equivalently, the positive root of

\[
27r^5+99r^4+101r^3-40r-12=0
\]

gives \(\widehat\beta=\log(r)\). At zero, \(U(0)=-7/12\) and \(\ell(0)=-\log(600)\). The model-based coefficient variance is \(I(\widehat\beta)^{-1}\), not a cluster-robust sandwich estimate.

| Quantity | Independent target |
| --- | --- |
| Log hazard ratio \(\widehat\beta\) | -0.5181598058136135 |
| Hazard ratio \(\exp(\widehat\beta)\) | 0.5956155884608161 |
| Observed information | 1.0934736206306656 |
| Model-based variance | 0.9145168032707050 |
| Standard error | 0.9563037191555333 |
| Initial partial log likelihood | -6.3969296552161464 |
| Fitted partial log likelihood | -6.2468419093423460 |

The fixed targets were evaluated at 80-digit precision from the risk table and analytic derivatives, without any `coxph()` fit. A separate interval-by-interval NumPy/SciPy calculation reproduced the coefficient, variance, and likelihood within absolute tolerance `1e-12`. The R tests compare the wrapper output with the fixed targets: `1e-7` for coefficient and uncertainty, `1e-9` for likelihood, and absolute fitted score below `1e-7`.

A base-R reproduction requiring no survival-model fit is:

```r
score <- function(beta) {
  r <- exp(beta)
  2 - 2 * r / (3 + 2 * r) - 3 * r / (2 + 3 * r) -
    3 * r / (1 + 3 * r) - r / (2 + r) - r / (1 + r)
}
beta <- stats::uniroot(score, interval = c(-2, 2), tol = 1e-12)$root
r <- exp(beta)
information <- 6 * r / (3 + 2 * r)^2 + 6 * r / (2 + 3 * r)^2 +
  3 * r / (1 + 3 * r)^2 + 2 * r / (2 + r)^2 + r / (1 + r)^2
loglik <- 2 * beta - log(3 + 2 * r) - log(2 + 3 * r) -
  log(1 + 3 * r) - log(2 + r) - log1p(r)
c(beta = beta, variance = 1 / information, loglik = loglik)
```

### Selection and representation boundaries

The tests retain the eight named interval rows, five events, and six subject IDs after adding and excluding three decoy subjects through `subset = selected`. One excluded row has a missing exposure, so selection must precede the selected-model completeness check. A missing exposure in a selected row must still error even with `na.action = na.omit`. A missing weight, which is outside the prechecked formula, must trigger the wrapper's changed-row error if the backend omits that interval.

Splitting D1 from `(0, 5]` into `(0, 2]` and `(2, 5]`, without changing its exposure, produces nine rows but still six subjects and five events. The coefficient, information-based uncertainty, and both likelihoods must match the same independent targets. At time 2 only the first split row contributes; D must not be counted twice. Reversing the input-row order must also preserve the targets.

The fixture is sensitive to endpoint mistakes. An independent risk-set calculation including F prematurely at time 2 gives a coefficient of about `-0.5978911`. Substituting B's and E's new exposure values already at their respective change times gives about `-0.4484472`, rather than the correct `-0.5181598`. These are deliberately incorrect risk conventions, not alternative estimates to use. The fixed risk-table and fitted-coefficient assertions jointly detect those changes.

The existing [counting-process contract tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-cox-timevarying.R) remain alongside this numerical reference. `survival` is a required dependency, so the new tests have no optional-backend skip and are included in required-dependency package checks.

## Reference scope

This reference covers one piecewise-constant binary covariate, nonoverlapping intervals, delayed entry, distinct event times, original-row selection, and model-based uncertainty. It assumes independent subjects, a suitable proportional-hazards model, appropriately observed covariates, and conditionally noninformative entry and censoring; the fixture does not establish these properties for a study.

It does not independently validate robust or clustered variances, recurrent events, frailty, arbitrary subject-history validity, causal effects of time-varying exposure, multivariable models, tied-event approximations, near-tie correction, or predictions. Checking six subjects' likelihood and information does not establish small-sample inferential coverage. The API remains experimental, and the [release gate](release-candidate.md) is separate.

## R help

Full arguments and return values: [`pharma_cox_timevarying()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_cox_timevarying.Rd). In an installed package, run `help("pharma_cox_timevarying", package = "PharmaStatsR")`.
