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

## R help

Full arguments and return values: [`pharma_multistate_model()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_multistate_model.Rd). In an installed package, run `help("pharma_multistate_model", package = "PharmaStatsR")`.
