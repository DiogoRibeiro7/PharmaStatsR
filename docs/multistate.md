# Multistate transition hazards

`pharma_multistate_model()` delegates to the optional
[`mstate::msfit()`](https://search.r-project.org/CRAN/refmans/mstate/html/msfit.html)
backend. Install `mstate` to use it. The return value contains **cumulative
transition hazards** for the specified covariate profile; it is not a table
of state occupation probabilities.

```r
library(PharmaStatsR)
install.packages("mstate")

trans <- mstate::trans.illdeath()
wide <- data.frame(
  illt = c(1, 1, 6, 6, 8, 9), ills = c(1, 0, 1, 1, 0, 1),
  dt = c(5, 1, 9, 7, 8, 12), ds = rep(1, 6),
  x1 = c(1, 1, 1, 0, 0, 0), x2 = 6:1
)
long <- mstate::msprep(
  time = c(NA, "illt", "dt"), status = c(NA, "ills", "ds"),
  data = wide, keep = c("x1", "x2"), trans = trans
)
long <- mstate::expand.covs(long, c("x1", "x2"))
fit <- survival::coxph(
  survival::Surv(Tstart, Tstop, status) ~ x1.1 + x2.2 + strata(trans),
  data = long, method = "breslow"
)
profile <- data.frame(
  trans = 1:3, x1.1 = c(0, 0, 0), x2.2 = c(0, 1, 0), strata = 1:3
)
hazards <- pharma_multistate_model(fit, trans, newdata = profile)
head(hazards$Haz)
```

The transition matrix determines which state changes are possible. The
`msprep()` data, Cox model, matrix, and `newdata` profile must describe the
same transitions. With covariates, `newdata` needs one row per transition and
a numeric `strata` column. According to the backend documentation, it can be
omitted only when the Cox right-hand side is exactly `~ strata(trans)`.
`mstate` recommends `method = "breslow"` for ties because this is the method
for which its results have been checked.

The helper checks the Cox class and square matrix shape before forwarding
arguments to `msfit()`; it does not validate event coding, transition
alignment, proportional hazards, or adequacy of the model. Its CI test
compares this example with a direct backend call. See the
[method inventory](method-inventory.md) and [limitations](limitations.md)
for the scope of review.

## Independent cumulative-hazard reference

The [numerical reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-multistate-reference.R) use a three-state illness-death structure with transitions (1\to2), (1\to3), and (2\to3). The Cox model has no covariates:

```r
survival::coxph(
  survival::Surv(Tstart, Tstop, status) ~ strata(trans),
  data = long, method = "breslow"
)
```

For a transition-specific event at time (t), the reference risk set uses the counting-process rule (T_{start}<t\le T_{stop}). With no covariates, the Breslow increment is (d(t)/Y(t)).

| Transition | Event time | At risk (Y(t)) | Events (d(t)) | Hazard increment |
| ---: | ---: | ---: | ---: | ---: |
| 1: 1 -> 2 | 1 | 6 | 1 | 1/6 |
| 1: 1 -> 2 | 2 | 5 | 1 | 1/5 |
| 1: 1 -> 2 | 4 | 3 | 1 | 1/3 |
| 2: 1 -> 3 | 3 | 4 | 1 | 1/4 |
| 2: 1 -> 3 | 5 | 1 | 1 | 1 |
| 3: 2 -> 3 | 4 | 2 | 1 | 1/2 |
| 3: 2 -> 3 | 5 | 2 | 1 | 1/2 |

Thus the expected cumulative hazards on the common time grid 1 through 6 are:

| Time | H(1 -> 2) | H(1 -> 3) | H(2 -> 3) |
| ---: | ---: | ---: | ---: |
| 1 | 1/6 | 0 | 0 |
| 2 | 11/30 | 0 | 0 |
| 3 | 11/30 | 1/4 | 0 |
| 4 | 7/10 | 1/4 | 1/2 |
| 5 | 7/10 | 5/4 | 1 |
| 6 | 7/10 | 5/4 | 1 |

The values are derived from the fixture's risk sets, not from a second `mstate::msfit()` call. The fitted wrapper is invoked with `variance = FALSE`, so this reference validates cumulative hazards only; variance and covariance estimation remain covered only by the existing backend comparison.

A boundary is deliberate at time 4 for transition 3. Subject 4 enters state 2 at exactly time 4 and therefore is **not** in the risk set for the event at time 4. Only subjects 1 and 5 satisfy (T_{start}<4\le T_{stop}), giving the increment (1/2).

The tests also set every transition-3 event indicator to zero. In this boundary, `mstate::msfit()` omits transition 3 from the returned `Haz` table rather than materializing a zero-valued curve. The independent arithmetic still implies zero cumulative hazard for that transition, but the wrapper preserves the backend's omission contract. Shuffling input rows must preserve the full hazard table. Adding 10 to every start and stop time shifts the output time grid by 10 while leaving every cumulative-hazard value unchanged.

Numerical hazard comparisons use absolute tolerance `1e-12`; fixed risk counts and subject identities use exact comparisons. The fixture has no simultaneous events within one transition, so it does not independently test tied-event approximations beyond the event/censor boundary at time 4.

The backend documentation states that `msfit()` returns cumulative transition hazards and recommends Breslow ties because that path has been checked by the package authors. The reference does not convert hazards to state-occupation probabilities.


## R help

Full arguments and return values: [`pharma_multistate_model()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_multistate_model.Rd). In an installed package, run `help("pharma_multistate_model", package = "PharmaStatsR")`.
