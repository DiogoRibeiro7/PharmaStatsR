# Population responses from saved allometric fits

`simulate_nlmixr_allometric()` draws replicated responses from the experimental
[weight-allometric oral model](allometric-nonlinear.md). It reuses the saved
original column names, reference weight, fitted parameters and variances. Each
replicate draws fresh subject effects and residual errors; fitted estimates
are held fixed throughout.

## Fit, simulate, and inspect

```r
library(PharmaStatsR)
# Requires optional nlmixr2est and nlmixr2data; fitting can take several minutes.
d <- nlmixr2data::theo_sd
fit <- fit_nlmixr_allometric(d, weight = "WT", control = list(seed = 99))

set.seed(227)
responses <- simulate_nlmixr_allometric(fit, d, nsim = 200)
dim(responses)
attr(responses, "simulation_parameters")

# Keep all relevant dose records until AFTER simulation.
observed <- d$EVID == 0
check <- plot_simulated_vpc(d[observed, ],
  responses[observed, , drop = FALSE], time = "TIME", response = "DV", bins = 4)
check
check$data
```

The response matrix has one row per input record and one column per replicate.
Columns are named `sim_1`, `sim_2`, etc.; original row order and nonempty row
names are preserved. Dose records contain `NA_real_`. Observation records
contain finite responses, including separate residual draws for duplicate
observations at the same subject/time. `nsim` defaults to 1000; the plotting
helper requires at least two replicates, and useful tail summaries usually
need many more. Assess Monte Carlo stability for the intended comparison.

Select the **same observation rows** from data and simulations after generating
responses. `plot_simulated_vpc()` rejects missing values and dose rows; it does
not infer an event schedule. Its ribbons summarize variation of within-bin
percentile statistics, not parameter confidence intervals or simultaneous
coverage. See the [percentile guide](simulated-vpc.md) for the exact calculation.

## What is drawn

For subject \(g\) and replicate \(r\), independently draw

\[
\eta_{ka,g,r}\sim N(0,\widehat\omega_{ka}),\qquad
\eta_{cl,g,r}\sim N(0,\widehat\omega_{cl}).
\]

The stored model uses

\[
k_{a,g,r}=\exp(\widehat{tka}+\eta_{ka,g,r}),\quad
CL_{g,r}=\exp(\widehat{tcl}+\eta_{cl,g,r})(W_g/W_{ref})^{0.75},\quad
V_g=\exp(\widehat{tv})(W_g/W_{ref}).
\]

Each observation receives \(Y_{i,r}=C_{g,r}(t_i)+\epsilon_{i,r}\), where
\(\epsilon_{i,r}\sim N(0,\widehat\sigma^2)\), independently across observations,
subjects, replicates and subject effects. The same subject effects apply to
all of that subject's dose and observation records within a replicate.
There is no random effect on volume.

The native fitted `omega` is used at full precision and must be a nonnegative
diagonal covariance with exactly `eta.ka` and `eta.cl`. Correlations, extra
effects, missing or nonfinite entries are rejected. Residual SD comes from the
fitted `add.sd` parameter. Starting values stored in `allometry$initial` are
not simulation parameters. Zero variances or residual SD are accepted when
present in an otherwise intact fit.

These are population replications: training IDs receive fresh effects just as
new IDs do. No fitted individual effects or parameter uncertainty are used.
The zero-effect concentrations returned by `predict_nlmixr_allometric()` are
not generally equal to the mean of these nonlinear population replications.

The additive error model permits **negative simulated responses**. The helper
retains them; clipping, censoring or discarding them would change the model.
If that error model is unsuitable for the intended outcome, specify and fit
an appropriate model rather than changing the simulator's output afterward.

## Schedules, original names, and saved fits

The event contract is the same as for
[allometric prediction](allometric-nonlinear.md#predict-from-a-saved-fit):
positive integer IDs, finite nonnegative time, positive weight constant within
each subject, explicit oral doses in uppercase `EVID`/`AMT`, and optional `CMT`.
Unsupported event modifiers are rejected. Use the original subject, time and
weight names from fitting, including literal names with spaces or punctuation.
The response column is unnecessary and ignored if supplied.

Supply the complete dose history relevant to each subject in every call,
including earlier doses whose effects persist. At least one dose per subject
is required, but omitted historical doses cannot be detected. Training doses
and prior calls are never consulted. Multiple doses must be explicit rows.
Keep units consistent with the fitted model.

Unsorted times, interleaved subjects, one-subject schedules and single
observations are supported. An empty table with the required typed columns
returns a zero-row matrix. Entirely dose-only schedules return an `NA` matrix;
neither case draws random numbers. All rows are validated even in those cases.

```r
path <- tempfile(fileext = ".rds")
saveRDS(fit, path)
restored <- readRDS(path)
set.seed(227)
stopifnot(identical(simulate_nlmixr_allometric(restored, d, 200), responses))
```

Native backend methods are loaded when needed, including in a fresh session.
Keep the model, fitted estimates, covariance and allometry metadata intact.
Older saved allometric fits without starting-value metadata are supported.
The returned `simulation_parameters` attribute records `theta`, `omega`,
`sd_residual`, `reference_weight`, and fixed `exponents` for inspection. In
`theta`, `tka`, `tcl`, and `tv` are logs of structural parameters; `add.sd`
is a response-scale standard deviation, not a logged parameter.

## Random stream and numerical boundaries

Record `set.seed()` and the [R RNG settings](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html)
when reproducibility matters. The helper consumes the current R stream and
does not set a seed for the caller. In each replicate, it calls `rnorm()` for:

1. Absorption effects for subjects in order of first appearance.
2. Clearance effects for subjects in the same order.
3. Residuals in input observation-row order.

When a batch has observations, any dose-only subjects also receive subject
draws. Relabeling IDs without changing their partition and first-appearance
order preserves seeded results. Reordering or splitting schedules can change
realized draws. Increasing `nsim` preserves the earlier replicate columns
under the same seed and input.

The [backend solver](https://nlmixr2.github.io/rxode2/reference/rxSolve.html)
evaluates supplied subject effects in batches with residual generation disabled.
Changes made by native loading or solving to R's random state are isolated, so
the caller's stream advances only through the documented draws. This does not
promise reproducibility across arbitrary R/backend versions or preservation
of the backend's separate internal random generator.

Invalid inputs fail before draws. Extremely large output or parameter tables
are rejected; available memory can impose a lower limit. Overflow, nonfinite
responses, or missing/duplicated backend records raise an error rather than
returning partial replicates. A numerical or backend failure after drawing can
consume the requested draws.

## Evidence and limits

The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-allometric-simulation.R)
independently reconstruct seeded subject effects and additive errors, evaluating
the closed-form oral concentration for every explicit dose. They cover different
weights, repeated doses, interleaved IDs, duplicate times, re-referencing,
literal names, batch prefixes, singleton/empty schedules and invalid output.

For two observations at the same subject/time, the shared concentration cancels:
their response difference has mean zero and variance \(2\widehat\sigma^2\).
A separate 10,000-replicate check tests this identity within six Monte Carlo
standard errors. Time-zero oral responses similarly have mean zero and variance
\(\widehat\sigma^2\); the checks retain their negative values. Native-fit tests
check fitted variance extraction, original-name mappings and restored fits.

This evidence covers the stated software and simulation model. It does not
establish identifiability, parameter recovery, calibrated uncertainty, clinical
suitability, or validity for a new population. The helper does not simulate
parameter uncertainty, refitting, dropout, missingness, censoring, infusions,
steady-state dosing or additional random-effect structures.
