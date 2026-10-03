# Emax dose-response curves

The three Emax helpers fit nonlinear curves. `pharma_emax()` and
`pharma_sigmoid_emax()` delegate to `stats::nls()` and return `nls` fits.
`pharma_emax_nlme()` delegates to `nlme::nlme()` and returns an `nlme` fit
for repeated doses within subjects. `nlme` is a required package dependency.
These wrappers do not select a scientific dose range or validate a study's
response definition.

## Curve and starts

With dose \(d\), the standard model is

\[
  m(d) = e_0 + \frac{E_{\max}d}{ED_{50}+d}.
\]

The sigmoid model adds a Hill exponent \(h\):

\[
  m(d) = e_0 + \frac{E_{\max}d^h}{ED_{50}^h+d^h}.
\]

`e0` is the response at zero dose under the model; `emax` is the change
toward the asymptote; `ed50` is the half-maximal dose when the parameters
and dose domain support that interpretation. The wrappers' initial guesses
are the minimum observed response for `e0`, response range for `emax`,
and median observed dose for `ed50`; the sigmoid helper starts `h` at 1.
They do not enforce positive doses, positive `ed50`, monotonicity, or
parameter bounds. Supply defensible starts and check identifiability,
convergence, and residuals before interpreting a fitted curve.

## Illustrative fits

The [example dose-response data](simulated-data.md) contain six subjects at
five doses each. Responses were generated from an Emax mean with a subject
intercept and observation noise; the values are unitless examples.

```r
library(PharmaStatsR)

dat <- pharma_dose_response
pooled <- pharma_emax(dat$dose, dat$response)
sigmoid <- pharma_sigmoid_emax(dat$dose, dat$response)
mixed <- pharma_emax_nlme(dat$dose, dat$response, subject = dat$subject)

stats::coef(pooled)
stats::coef(sigmoid)
summary(mixed)
```

The first two fits use all 30 rows in a single curve and do not model
within-subject dependence. The mixed helper uses a subject-specific random
`e0` by default (`e0 ~ 1 | subject`), while `emax` and `ed50` are common
fixed effects. When `start = NULL`, it first fits a pooled `nls` curve to
obtain fixed-effect starting values; a failure at this step stops the mixed
fit. Its internal `nlmeControl(returnObject = TRUE)` can return an object
after the maximum iterations with a nonconvergence warning. Inspect that
warning and the fit before using estimates; a returned object is not proof
of convergence. See the [nlme control reference](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/nlmeControl.html).

The installed help for [`pharma_emax()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_emax.Rd),
[`pharma_sigmoid_emax()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_sigmoid_emax.Rd),
and [`pharma_emax_nlme()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_emax_nlme.Rd)
lists the arguments and return classes. The [evidence inventory](method-inventory.md)
marks all three as candidate methods with class-level smoke tests. These
tests establish that the example fits run; they do not independently check
parameter recovery, uncertainty, or the suitability of any curve for a study.
