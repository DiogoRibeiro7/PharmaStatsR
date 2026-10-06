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

## Evidence layers

The evidence for this helper is deliberately split into two layers. The
component models have independent numerical checks; the fitted joint model is
checked as an installed-backend contract. The latter is **not** an independent
reimplementation of the joint likelihood.

### Independent component reference

The [component reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-joint-model-reference.R)
use six matched synthetic subjects. Each subject has longitudinal measurements
at times 0, 1, and 2 under a random-intercept model,

\[
Y_{ij}=10+u_i+2t_j+e_j,
\]

with subject shifts \((-1,0,1,-2,2,0)\) and the common within-subject pattern
\(e=(0.5,-1,0.5)\). The subject shifts sum to zero. The within-subject pattern
is orthogonal to both the intercept and time:

\[
\sum_j e_j=0,\qquad \sum_j t_j e_j=0.
\]

For the balanced common random-intercept covariance, these relations leave the
fixed effects at \(\beta_0=10\) and \(\beta_1=2\). The test verifies the fixed
normal-equation orthogonality directly and checks the nlme fixed effects against
those targets.

The matched survival component has six subjects, binary group
\((0,1,0,1,0,1)\), follow-up times 3 through 8, and events for subjects 1, 2,
4, and 6. Its event risk sets give the one-covariate Cox score equation

\[
-\frac{r}{1+r}+\frac{2}{2+3r}+\frac{1}{1+2r}=0,\qquad
r=\exp(\gamma),
\]

or equivalently

\[
6r^3-9r-4=0.
\]

The unique positive root gives
\(\gamma=0.3401437586869536\). The test evaluates the risk-set score independently
and compares the fitted Cox coefficient with that fixed target. It also checks
the Cox design values, event count, matched subject order, and compatible
longitudinal/survival time ranges.

These calculations validate only the two **component models** used to construct
a compatible joint-model input. They do not validate the combined likelihood.

### Installed joint-backend contract

The package's existing AIDS example remains the fitted joint-model execution
case using method weibull-PH-GH. The backend test now checks more than class:
the normalized method and time variable, value parameterization, successful
convergence code, repeated-measure and subject counts, event count, coefficient
blocks and names, finite coefficient values, positive longitudinal residual
scale, and a finite log-likelihood with the expected subject count attribute.

Those checks are contracts of the JM object. The JM documentation defines
convergence code zero as success and documents n as the number of sample units,
N as the number of longitudinal measurements, ni as the per-subject measurement
counts, d as the event indicators, and the coefficient and log-likelihood
components.

No independent claim is made for the joint likelihood, the association
parameter estimator, Gauss-Hermite or Gauss-Kronrod integration, the joint-model
covariance matrix, dynamic prediction, or causal interpretation. Those remain
backend-only evidence and study-specific responsibilities.


## R help

Full arguments and return values: [`pharma_joint_model()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_joint_model.Rd). In an installed package, run `help("pharma_joint_model", package = "PharmaStatsR")`.
