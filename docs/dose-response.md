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
parameter bounds. Nonnegative doses, positive `ed50`, and (for the sigmoid
curve) positive `h` give the usual half-maximal interpretation; the caller
must enforce those scientific constraints. Supply defensible starts and
check identifiability, convergence, and residuals before interpreting a fit.

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
records the three numerical reference cases alongside the earlier smoke
tests. The [reference test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-dose-response-references.R)
uses five prespecified doses (0, 1, 2, 4, 8), each measured twice with
balanced residuals of -0.05 and +0.05. For the standard curve, the independent
target parameters are `e0 = 2`, `emax = 6`, `ed50 = 2`, giving mean responses
(2, 4, 5, 6, 6.8). For the sigmoid curve, `e0 = 1`, `emax = 8`,
`ed50 = 2`, `h = 2` give means (1, 2.6, 5, 7.4, 1 + 8 * 64 / 68).
Symmetric paired residuals leave these curves as the least-squares targets
while keeping residual variance nonzero. The test also calculates
`sigma^2 (J'J)^(-1)` from the analytic curve derivatives and compares
coefficient covariance diagonals, rather than obtaining the target from
another wrapper fit.

The mixed case repeats these five doses twice within eight subjects with
baseline offsets (-0.4, -0.3, -0.2, -0.1, 0.1, 0.2, 0.3, 0.4) and paired
residuals of -0.08 and +0.08. Its population curve is the standard target
above; a random subject baseline is the only varying curve parameter.
The test compares fixed coefficients and population predictions to those
known means and checks that estimated baseline effects track the assigned
offsets. All three cases also try a single-dose design, where the parameters
cannot be separated and fitting must fail. These fixtures cover that design
and approximate uncertainty under its nonlinear least-squares assumptions;
they do not establish convergence for arbitrary starts or data, valid
confidence intervals for all studies, or clinical suitability.
