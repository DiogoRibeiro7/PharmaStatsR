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

## Independent no-censoring reference

The self-contained [Fine-Gray reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-fine-gray-reference.R) use eight distinct subjects with a numeric binary covariate, five target events, three competing events, and **no right censoring**. All observed times are unique. The numbers below are derived from explicit risk sets, not from another `crr()` call or its implementation.

### Fixture and subdistribution risk sets

Each row represents one subject. Status 1 is the target event, status 2 is the competing event, and the unused code 0 denotes censoring.

| Subject | Time | Status | Exposure |
| --- | --- | --- | --- |
| subject-01 | 1 | 2 | 1 |
| subject-02 | 2 | 1 | 0 |
| subject-03 | 3 | 1 | 1 |
| subject-04 | 4 | 2 | 0 |
| subject-05 | 5 | 1 | 0 |
| subject-06 | 6 | 1 | 1 |
| subject-07 | 7 | 2 | 1 |
| subject-08 | 8 | 1 | 0 |

At target-event time `t`, the subdistribution risk set includes subjects whose event time is at least `t`, **plus subjects who already experienced the competing event**. No subject was censored, so the censoring-survival weights are one. This is a special case of the weighted estimating-equation approach described in the [official `crr()` documentation](https://search.r-project.org/CRAN/refmans/cmprsk/html/crr.html) and Fine and Gray (1999), DOI [10.1080/01621459.1999.10474144](https://doi.org/10.1080/01621459.1999.10474144).

The following IDs abbreviate the numeric suffix of `subject-ID`. Columns `n0` and `n1` count risk-set subjects by exposure, while `x_event` is the target-event subject's exposure. Exactly one target event occurs at each listed time.

| Target-event time | Subdistribution risk-set IDs | n0 | n1 | x_event |
| --- | --- | --- | --- | --- |
| 2 | 01-08 | 4 | 4 | 0 |
| 3 | 01, 03-08 | 3 | 4 | 1 |
| 5 | 01, 04-08 | 3 | 3 | 0 |
| 6 | 01, 04, 06-08 | 2 | 3 | 1 |
| 8 | 01, 04, 07, 08 | 2 | 2 | 0 |

Subject 01 remains in **every** target-event risk set despite experiencing the competing event at time 1. Subject 04 remains after time 4, and subject 07 remains at time 8. Removing these subjects at their competing events would instead produce cause-specific risk sets. At the correct Fine-Gray coefficient below, that different score is approximately `0.4276643827`, rather than zero; the test explicitly checks that the two constructions differ.

### Likelihood, score, and information

Write `r = exp(beta)`. With no tied target events, each row contributes `x_event * beta - log(n0 + n1 * r)` to the log pseudo-likelihood. Summing the table gives

```text
ell(beta) = 2*beta - log(24) - 3*log(1+r) - log(3+4*r) - log(2+3*r)
U(beta)   = 2 - 3*r/(1+r) - 4*r/(3+4*r) - 3*r/(2+3*r)
I(beta)   = 3*r/(1+r)^2 + 12*r/(3+4*r)^2 + 6*r/(2+3*r)^2
```

Here `U` is the first derivative and `I` is minus the second derivative. The factor 24 is `4 * 3 * 2` from the three denominators proportional to `1+r`. Setting the score to zero gives

```text
36*r^3 + 34*r^2 - 11*r - 12 = 0.
```

Its unique positive root is `r_hat = 0.5787373090319948`, and `beta_hat = log(r_hat)`. The information is positive for every finite coefficient, and the score changes sign, so this is a finite maximum.

| Quantity | Independent target |
| --- | --- |
| Exposure coefficient | -0.5469066020605744 |
| Subdistribution hazard ratio | 0.5787373090319948 |
| Observed information | 1.1911997895342392 |
| Inverse information | 0.8394897386533299 |
| Log pseudo-likelihood at beta = 0 | -8.8128434335171952 |
| Maximized log pseudo-likelihood | -8.6303388076825458 |

At zero, the score and information have exact rational values `U(0) = -47/70` and `I(0) = 6051/4900`; the log pseudo-likelihood is `-log(6720)`. A separate test uses the documented `init = 0, maxiter = 0` option to check these derivatives without optimization. That call is an evaluation at a fixed coefficient, not a converged fit.

### Baseline subdistribution-hazard jumps

For this single-event-per-time fixture, the Breslow-type baseline jump at `t_j` is `1/(n0_j + n1_j * r_hat)`, evaluated at exposure zero. The tests check both the ordered target-event times in `uftime` and these increments in `bfitj`:

| Time | Independent baseline jump |
| --- | --- |
| 2 | 0.1583544004247850 |
| 3 | 0.1881485514861691 |
| 5 | 0.2111392005663800 |
| 6 | 0.2676507702220366 |
| 8 | 0.3167088008495699 |

At coefficient zero, the corresponding jumps are exactly `(1/8, 1/7, 1/6, 1/5, 1/4)`. These are increments of cumulative subdistribution hazard, not cumulative incidence probabilities.

### Reproducing the independent targets

This base-R calculation uses only the analytic expressions and a scalar root search. It does not call a survival-model fitting function:

```r
score <- function(beta) {
  r <- exp(beta)
  2 - 3 * r / (1 + r) - 4 * r / (3 + 4 * r) - 3 * r / (2 + 3 * r)
}
beta_hat <- stats::uniroot(score, c(-2, 2), tol = 1e-12)$root
r_hat <- exp(beta_hat)
information <- 3 * r_hat / (1 + r_hat)^2 +
  12 * r_hat / (3 + 4 * r_hat)^2 + 6 * r_hat / (2 + 3 * r_hat)^2
loglik <- function(beta) {
  r <- exp(beta)
  2 * beta - log(24) - 3 * log1p(r) - log(3 + 4 * r) - log(2 + 3 * r)
}
c(coefficient = beta_hat, ratio = r_hat, information = information,
  inverse_information = 1 / information,
  null_loglik = loglik(0), fitted_loglik = loglik(beta_hat))
1 / (c(4, 3, 3, 2, 2) + r_hat * c(4, 4, 3, 3, 2))
```

The documented targets were also recomputed with 80-decimal-digit arithmetic in Python and checked against a separate array-based calculation that reconstructs each risk set from the subject records. The two calculations agree within absolute tolerance `1e-12`. Neither calculation obtains expected values from `crr()`.

### Assertions and scope

The fitted reference explicitly uses `init = 0`, `gtol = 1e-10`, `maxiter = 50`, and `variance = TRUE`. Tests compare the coefficient, ratio, information, inverse information, and hazard jumps with fixed targets at testthat tolerance `1e-7`; the fitted log pseudo-likelihood uses `1e-9`. The fitted score must have absolute magnitude below `1e-7`. Exact-zero and independent-expression comparisons use `1e-12`, and the integer event times use zero numerical tolerance. These are numerical test tolerances, not inferential confidence bounds.

The risk-set test verifies explicit subject identities and independently reconstructs likelihood, score, information, and jumps at four coefficients. Further tests relabel `(target, competing, censoring)` as `(11, 7, -1)` and `(2, 1, 9)`, permute row order, and reject an absent target event before optimization. No censoring observations are added by relabelling an unused censoring code. Existing [contract and invalid-input tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-competing-risks.R) and the missing-backend guard remain unchanged.

The arithmetic risk-set test requires no optional package. Fitted-output tests require `cmprsk` and run in the all-Suggests validation job; they explicitly skip when that backend is absent. This does not expand the required dependencies or change a workflow.

**Information is not coefficient covariance.** The backend separately returns `inf`, `invinf`, and `var`. This reference validates the first two, but does not independently derive or validate `var`, standard errors, or confidence intervals. Requesting `variance = TRUE` makes these outputs available; it does not establish their correctness.

This reference also does not independently validate estimated censoring weights, `cengroup`, tied events, time-varying effects, predictions, causal effects, or study suitability. It must not be interpreted as evidence for a cause-specific hazard ratio. The API remains experimental, and the release decision remains separate.

## R help

Full arguments and return values: [`pharma_competing_risks()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_competing_risks.Rd). In an installed package, run `help("pharma_competing_risks", package = "PharmaStatsR")`.
