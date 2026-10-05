# Landmark Cox analysis

`pharma_landmark_analysis()` fits an ordinary Cox model among subjects whose recorded follow-up extends **strictly beyond** a prespecified landmark. It subtracts the landmark from their observed follow-up times and retains their event indicators. An event or censoring at the landmark does not enter the risk set.

```r
library(PharmaStatsR)

fit <- pharma_landmark_analysis(
  survival::Surv(time, status) ~ treatment,
  data = pharma_survival,
  landmark = 5
)
summary(fit)
```

The response must be right-censored `Surv(time, status)` with a complete time and status for every row considered. `subset` accepts a logical expression in the original data or a complete logical vector with one value per row. It selects rows **before** the landmark risk set is formed. Covariates must be complete among the remaining subjects; missing covariates in excluded subjects do not prevent fitting.

## Direct reference

The following constructs the same risk set and time origin explicitly. Comparing coefficients and log likelihoods is a useful check when adapting the example to a study design. It is a **backend comparison**, not independent numerical evidence.

```r
selected <- pharma_survival[
  pharma_survival$time > 5,
  , drop = FALSE
]
selected$time <- selected$time - 5
reference <- survival::coxph(
  survival::Surv(time, status) ~ treatment,
  data = selected
)
all.equal(unname(stats::coef(fit)), unname(stats::coef(reference)))
```

## Independent landmark Cox reference

The self-contained [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-landmark-cox-reference.R) fix the landmark at `L = 5`, use a numeric binary covariate `exposure`, and request `ties = "breslow"`, `robust = FALSE`, and `init = 0`. The [survival backend documentation](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/coxph.html) describes these fitting options. The choice of Breslow is explicit; this fixture does not test the default Efron rule.

### Fixture and eligible population

Each row represents one distinct subject. The twelve retained subjects reproduce the [ordinary Cox reference](survival-regression.md#independent-ordinary-cox-reference) after adding five to every follow-up time. Six extra subjects test selection rather than contributing to its likelihood. All predictors are initially complete; missing-data variants are described below.

| Subject ID | Original time | Event | Exposure | Original-row selected | Retained time |
| --- | --- | --- | --- | --- | --- |
| subject-01 | 6 | 1 | 0 | TRUE | 1 |
| subject-02 | 7 | 1 | 0 | TRUE | 2 |
| subject-03 | 7 | 0 | 0 | TRUE | 2 |
| subject-04 | 8 | 1 | 0 | TRUE | 3 |
| subject-05 | 10 | 0 | 0 | TRUE | 5 |
| subject-06 | 11 | 1 | 0 | TRUE | 6 |
| subject-07 | 6 | 0 | 1 | TRUE | 1 |
| subject-08 | 7 | 1 | 1 | TRUE | 2 |
| subject-09 | 8 | 1 | 1 | TRUE | 3 |
| subject-10 | 8 | 0 | 1 | TRUE | 3 |
| subject-11 | 9 | 1 | 1 | TRUE | 4 |
| subject-12 | 11 | 0 | 1 | TRUE | 6 |
| before-event | 3 | 1 | 0 | TRUE | Excluded: before L |
| before-censor | 4 | 0 | 1 | TRUE | Excluded: before L |
| at-event | 5 | 1 | 0 | TRUE | Excluded: exactly L |
| at-censor | 5 | 0 | 1 | TRUE | Excluded: exactly L |
| excluded-event | 5.5 | 1 | 1 | FALSE | Excluded: subset |
| excluded-censor | 105 | 0 | 0 | FALSE | Excluded: subset |

The original-row subset contains sixteen subjects. The strict landmark restriction leaves exactly `subject-01` through `subject-12`: twelve subjects, seven events, and five censorings. The two otherwise eligible subset exclusions are complete observations. Neither they nor the four observations ending at or before the landmark belong in any fitted risk set.

### Risk sets and partial likelihood

At a shifted event time `t`, a retained subject is at risk when their shifted follow-up is at least `t`. Thus a censoring at the same time as an event remains in that event's denominator. In the following table, IDs abbreviate the numeric suffix of `subject-ID`; `n0`, `n1` count subjects at risk by exposure, and `d0`, `d1` count events.

| Shifted event time | Retained IDs at risk | n0 | n1 | d0 | d1 |
| --- | --- | --- | --- | --- | --- |
| 1 | 01-12 | 6 | 6 | 1 | 0 |
| 2 | 02-06, 08-12 | 5 | 5 | 1 | 1 |
| 3 | 04-06, 09-12 | 3 | 4 | 1 | 1 |
| 4 | 05, 06, 11, 12 | 2 | 2 | 0 | 1 |
| 6 | 06, 12 | 1 | 1 | 1 | 0 |

Let `beta` be the exposure coefficient and `r = exp(beta)`. With the Breslow rule, each event-time contribution is `d1 * beta - (d0 + d1) * log(n0 + n1 * r)`. Summing this table gives the log partial likelihood, its score, and its observed information:

```text
ell(beta) = 3*beta - log(300) - 5*log(1+r) - 2*log(3+4*r)
U(beta)   = 3 - 5*r/(1+r) - 8*r/(3+4*r)
I(beta)   = 5*r/(1+r)^2 + 24*r/(3+4*r)^2
```

The constant 300 is `6 * 5^2 * 2`. The score equation reduces to `16*r^2 + 2*r - 9 = 0`, with positive root `r_hat = (sqrt(145) - 1)/16`. The finite maximum is `beta_hat = log(r_hat)`, and the model-based variance is `1/I(beta_hat)`. Expected values come from these expressions, not a second `coxph()` call.

| Quantity | Independent target |
| --- | --- |
| Exposure coefficient | -0.3709192553359674 |
| Hazard ratio | 0.6900996611745185 |
| Observed information | 1.7071078394690232 |
| Model-based variance | 0.5857860744819957 |
| Model-based standard error | 0.7653666274942981 |
| Initial log partial likelihood at beta = 0 | -13.0613386755665542 |
| Maximized log partial likelihood | -12.9424910951151456 |

The following base-R calculation reproduces the targets independently of the fitting backend:

```r
r_hat <- (sqrt(145) - 1) / 16
beta_hat <- log(r_hat)
information <- 5 * r_hat / (1 + r_hat)^2 +
  24 * r_hat / (3 + 4 * r_hat)^2
loglik <- function(beta) {
  r <- exp(beta)
  3 * beta - log(300) - 5 * log1p(r) - 2 * log(3 + 4 * r)
}
c(
  coefficient = beta_hat,
  hazard_ratio = r_hat,
  information = information,
  variance = 1 / information,
  standard_error = sqrt(1 / information),
  initial_loglik = loglik(0),
  fitted_loglik = loglik(beta_hat)
)
```

### Assertions, tolerances, and boundaries

The reference checks the coefficient, hazard ratio, standard error, covariance, likelihood, subject and event counts, selected subject identities, covariate coding, and returned shifted response. It also reconstructs the tabulated risk sets from the fixture and compares the table-based likelihood with the analytic expression at four coefficient values.

Numerical comparisons use `testthat::expect_equal()` tolerances of `1e-7` for coefficients and uncertainty and `1e-9` for fitted likelihoods. The fitted score must have absolute magnitude below `1e-7`. Independent expression checks use `1e-12`. Subject identities use exact equality; the integer shifted times and event indicators use zero numerical tolerance. These are testthat comparison tolerances, not confidence bounds or a claim of universal decimal accuracy.

Adding 100 to every original time and to the landmark preserves the eligible identities and all shifted responses exactly. Coefficients, covariance, and likelihood are compared at `1e-9`, and the translated fit must still match the independent targets. Reversing input rows and supplying an original-row logical selection vector also retain those targets. The fixture uses well-separated integer event times; it does not assess near-tie floating-point correction.

Missing predictors in the four observations at or before the landmark, or in the two subset-excluded observations, do not prevent the reference fit. A missing predictor in an eligible observation must error. Missing time or status in a selected observation must error even when its other values place it before or exactly at the landmark: eligibility cannot be inferred from incomplete follow-up. Missing response values in original-row exclusions are not considered. An empty original subset and an empty landmark population have separate input-policy errors, tested without depending on optimizer diagnostics.

The existing [contract and backend-comparison tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-landmark-analysis.R) remain unchanged. Both test files run with required R dependencies and do not skip behind an optional backend. This reference introduces no estimator, signature, dependency, or workflow change.

## Interpretation and limits

The fitted hazard ratio compares subjects **conditional on being event-free and observed beyond time 5**. It does not describe events before that time or remove selection bias from a time-dependent exposure. Choose the landmark before looking at outcomes, check the event coding and censoring assumptions, and consider a [counting-process Cox model](cox-timevarying.md) for covariates that change during follow-up. See [Kaplan–Meier and log-rank](kaplan-meier.md) for unadjusted right-censored summaries and [limitations and validation](limitations.md) for the package's general scope.

This fixed reference does not validate data-driven landmark selection, causal treatment effects, immortal-time-bias prevention in an arbitrary study, robust variances, time-varying covariates, competing risks, baseline hazard estimates, prediction calibration, or censoring assumptions. The statistical API remains experimental and the release decision remains separate.

## R help

Full arguments and return values: [`pharma_landmark_analysis()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_landmark_analysis.Rd). In an installed package, run `help("pharma_landmark_analysis", package = "PharmaStatsR")`.
