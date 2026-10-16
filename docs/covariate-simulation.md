# Replicated responses from fitted covariate models

`simulate_covariate_model()` generates response matrices for the Gaussian
random-intercept model fitted by `fit_covariate_model()`. It holds fitted fixed
effects and variances constant, draws fresh subject effects and residual errors
in each replicate, and preserves the input row order. The output can be passed
directly to `plot_simulated_vpc()`.

This experimental helper supports one random subject intercept with independent,
constant-variance Gaussian residuals. It rejects random slopes, nested groups,
nonlinear fits, residual correlation, and residual variance weights. It is not
a general simulator for every `nlme` model.

## Fit, simulate, and inspect

```r
library(PharmaStatsR)
time <- rep(c(-1, 0, 1), 4)
observed <- data.frame(
  SubjectID = rep(1:4, each = 3), Time = time,
  DV = 2 + 1.5 * time + rep(c(-3, -1, 1, 3), each = 3) +
    rep(c(1, -2, 1), 4)
)
fit <- fit_covariate_model(observed, "DV", "SubjectID", "Time")
set.seed(217)
simulations <- simulate_covariate_model(fit, observed, nsim = 500)
dim(simulations)
attr(simulations, "simulation_parameters")
plot_simulated_vpc(observed, simulations, bins = 3)
```

The fixed dataset above is a balanced numerical reference rather than a random
sample from a clinical population. The [mixed-model guide](covariate-mixed-model.md)
derives its estimated intercept `2`, slope `1.5`, residual variance `24/7`, and
random-intercept variance `116/21`.

For row i, subject g, and replicate r, simulation uses

```text
Y[i, r] = X[i, ] beta_hat + b[g, r] + e[i, r]
b[g, r] ~ N(0, tau_hat^2)
e[i, r] ~ N(0, sigma_hat^2)
```

All distinct subject effects, residuals, and replicates are independent. Rows
with the same ID share their subject effect even when not adjacent. The helper
uses `predict_covariate_model(..., level = 0)` for the fixed-effect mean and
[nlme's full-precision random-effects covariance](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/getVarCov.html)
for the subject variance; it does not parse a rounded printed variance table.

For the fixture, the marginal response variance is `116/21 + 24/7 = 188/21`.
Two rows of the same subject have covariance `116/21`; distinct subjects have
covariance zero. The variance of a same-subject response difference is `48/7`
because the shared intercept cancels.

## New rows and original column names

No response column is needed. Supply original covariate names and the original
subject identifier, including for fits made with `repair_names = TRUE`:

```r
literal <- observed
names(literal) <- c("subject id", "visit time", "response value")
repaired <- fit_covariate_model(
  literal, "response value", "subject id", "visit time", repair_names = TRUE
)
future <- data.frame(subject = c("new-A", "new-B", "new-A"), time = c(-1, 0, 1))
names(future) <- c("subject id", "visit time")
set.seed(217)
future_responses <- simulate_covariate_model(repaired, future, nsim = 5)
future_responses
```

The two `new-A` rows share a random draw within each replicate. Numeric,
logical, character, and factor identifiers are supported; unused factor levels
do not create extra simulated subjects. Known training identifiers have exactly
the same simulation meaning as new labels: their effects are redrawn from the
estimated population distribution, without using their fitted BLUPs.

For conditional point predictions of known subjects, use
`predict_covariate_model(..., level = 1)` instead. Conditional response simulation
for existing subjects is outside this helper's scope. Relabeling identifiers
while preserving their partition and order of first appearance preserves
realizations under the same seed; reordering rows need not do so.

## Random stream and returned values

Call `set.seed()` before simulation and record the
[R RNG settings](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html)
when reproducibility matters. The helper consumes the caller's random stream;
it neither resets nor restores it. For each replicate it draws subject effects
in order of first appearance, then residual errors in input row order. Changing
the batch, row order, or number of subjects can change realized draws under the
same seed. The model distribution remains the documented one.

The result has one row per input row and columns `sim_1`, `sim_2`, etc.
Nonempty row names are preserved. `attr(result, "simulation_parameters")`
contains the named fixed-effect `mean` vector and full-precision `sd_subject`
and `sd_residual`. Empty data with the required columns return a zero-row matrix
without consuming or initializing RNG state. The plotting helper requires
nonempty data and at least two replicates.

Saved models retain the name mapping and training schema:

```r
model_path <- tempfile(fileext = ".rds")
saveRDS(repaired, model_path)
restored <- readRDS(model_path)
set.seed(217)
stopifnot(identical(
  simulate_covariate_model(restored, future, nsim = 5), future_responses
))
unlink(model_path)
```

In a fresh session, load PharmaStatsR and restore the model; the helper loads
the declared nlme dependency's methods as needed. Keep the stored training data
and fitted structure intact. Neither the data nor the fit is modified.

## Limits and evidence

- Estimated fixed effects and variances are held fixed. No parameter uncertainty,
  refitting, bootstrap, posterior sampling, or model selection is performed.
- Newdata must contain observed, finite covariates and IDs; new categorical
  predictor levels fail. A supplied response is ignored. Missing responses in
  training do not imply an automatic simulation-row exclusion. For comparison
  plots, explicitly select the same observed cohort in data and simulations.
- The helper does not model missingness, censoring, dropout, dose events, or
  residual serial correlation. It uses the supplied observation schedule and
  grouping only. A scientific model assessment still needs an appropriate
  design and enough replications to assess Monte Carlo stability.
- Inputs are validated before drawing. Nonfinite generated responses caused by
  extreme scales raise an error; such generation errors can consume RNG state.

The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-model-simulation.R)
reconstruct seeded draws using the hand-derived means and variances above. A
separate 40,000-replicate check compares means and covariance against the
analytic Gaussian moments with six Monte Carlo standard errors of tolerance.
Additional checks cover ID types, name repair, categorical predictors, restored
models, empty/singleton inputs, unsupported model structures, RNG behavior, and
composition with the percentile plot. These checks cover the stated simulator;
they do not establish model adequacy for a study.
