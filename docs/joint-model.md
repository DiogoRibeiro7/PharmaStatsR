# Joint longitudinal and survival models

`pharma_joint_model()` passes an `nlme::lme` longitudinal fit and a
`survival::coxph` time-to-event fit to the optional
[`JM::jointModel()`](https://search.r-project.org/CRAN/refmans/JM/html/jointModel.html)
backend. Install `JM` before calling the wrapper. `nlme` and `survival` are
required package dependencies.

```r
install.packages("JM")
library(JM)
data("aids", package = "JM")
data("aids.id", package = "JM")

longitudinal <- nlme::lme(
  sqrt(CD4) ~ obstime * drug - drug,
  random = ~ 1 | patient, data = aids
)
survival_fit <- survival::coxph(
  survival::Surv(Time, death) ~ drug, data = aids.id, x = TRUE
)
fit <- pharma_joint_model(
  longitudinal, survival_fit, timeVar = "obstime",
  method = "weibull-PH-GH"
)
summary(fit)
```

The Cox fit must retain its design matrix with `x = TRUE`. The longitudinal
fit must inherit from `nlme::lme`; `lme4::lmer` returns a different class and
is not accepted by `JM::jointModel()`. The helper checks those requirements
and that `timeVar` is a nonempty name in stored longitudinal data. It reports
an installation hint if `JM` is missing. Attach `JM` with `library(JM)` before
calling the helper. The backend uses functions from attached dependencies
without importing them into its namespace; a namespace-only `JM::jointModel()`
call fails to find `nlme::pdMatrix`.

The two source models must have **the same subjects in the same order**, and
the time scales must agree. Check the subject identifiers and records before
fitting: this wrapper cannot establish their alignment. The backend has
further model-structure and convergence requirements. The CI test fits this
package-provided example once to exercise the installed backend; it does not
validate a joint model or its assumptions for a study.

## R help

Full arguments and return values: [`pharma_joint_model()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_joint_model.Rd). In an installed package, run `help("pharma_joint_model", package = "PharmaStatsR")`.
