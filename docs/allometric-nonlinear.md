# Weight-allometric nonlinear fitting

`fit_nlmixr_allometric()` is an experimental wrapper for one prespecified
one-compartment oral model fitted by SAEM in optional `nlmixr2est`. It uses body
weight in the structural model and returns the native fit. The original
example-only `fit_nlmixr_model()` keeps its existing behavior.

## Model and units

For subject \(i\), let \(r_i=W_i/W_{ref}\). The model is

\[
k_{a,i}=\exp(tka+\eta_{ka,i}),\quad
CL_i=\exp(tcl+\eta_{cl,i})r_i^{0.75},\quad
V_i=\exp(tv)r_i.
\]

The two subject effects are independent, zero-mean normal variables with
estimated variances. There is no random effect on volume. The observation
model is \(Y_{ij}=C_i(t_{ij})+\epsilon_{ij}\), with independent additive normal
residual error and an estimated standard deviation. The structural model uses
first-order absorption and elimination with bioavailability implicitly one;
clearance and volume are apparent parameters. `exp(tcl)` and `exp(tv)` describe
the reference weight at zero subject effects.

The powers 0.75 and 1 are fixed assumptions, not estimated covariate effects or
a statement of suitability for every population. The wrapper does not screen
covariates, estimate these powers, or model changing weight. The backend
[model-piping guide](https://nlmixr2.org/articles/modelPiping.html) illustrates
fixed weight effects; its [initialization documentation](https://nlmixr2.github.io/rxode2/reference/ini.html)
describes the parameter and random-effect specification.

Weight and `reference_weight` must share units: use 70 for weight measured in
kg, or 70000 for the equivalent reference in g. Other units must also agree:
for example, dose in mg, time in hours, volume in L, clearance in L/hour, and
response in mg/L. No conversion is performed. Default initial log parameters
remain `tka = 0`, `tcl = 0`, `tv = 1`, with initial subject variances and residual
standard deviation of 1. Use `initial` to override selected starts on the
scales described below.

## Fit and inspect

```r
# Install these optional packages once if needed:
# install.packages(c("nlmixr2est", "nlmixr2data"))
library(PharmaStatsR)
fit <- fit_nlmixr_allometric(
  nlmixr2data::theo_sd, weight = "WT", reference_weight = 70,
  control = list(seed = 99)
)
attr(fit, "allometry")
head(fit$PRED)
```

This runs a full stochastic fit and can take several minutes. `control` is a
uniquely named list of arguments accepted by `nlmixr2est::saemControl()`;
unknown names fail. Backend defaults are retained except `print = 0`. A
recorded seed helps reproduce a fit within the same software environment;
backend random streams and convergence behavior still apply. The wrapper does
not restore the caller's RNG state. Inspect convergence, sensitivity to starts,
identifiability, residual structure and uncertainty separately. A successful
fit is not evidence of a global optimum or calibrated inference. The narrow
wrapper supports explicit starting values for this model; use the backend
directly for alternative structural models, parameter bounds, or fixed
parameter values.

## Explicit starting values

`initial` is a named list. Unspecified entries keep the defaults below, and all
supplied values must be positive finite numeric scalars. Unknown or duplicate
names, missing values, zero, and nonnumeric values fail before the backend is
loaded. Names are case-sensitive. A numeric vector is not a named list.

| Name | Meaning and scale | Default | Backend initialization |
| --- | --- | ---: | --- |
| `ka` | Absorption rate, inverse time | 1 | `tka = log(ka)` |
| `cl` | Apparent clearance at reference weight and zero subject effects, volume/time | 1 | `tcl = log(cl)` |
| `v` | Apparent volume at reference weight, volume | `exp(1)` | `tv = log(v)` |
| `eta_ka_var` | Variance of the log-absorption subject effect | 1 | Diagonal `eta.ka` variance |
| `eta_cl_var` | Variance of the log-clearance subject effect | 1 | Diagonal `eta.cl` variance |
| `residual_sd` | Additive residual standard deviation, response units | 1 | `add.sd` |

Subject-effect entries are **variances**, not standard deviations or
coefficients of variation. `residual_sd` is a **standard deviation**, not a
variance. All six parameters remain free to be estimated. Zero starts do not
fix a parameter or remove a random effect and are rejected. The fixed weight
exponents and independence of subject effects are unchanged.

For example, supply a different starting model on the public example data:

```r
fit_alternative <- fit_nlmixr_allometric(
  nlmixr2data::theo_sd, weight = "WT", reference_weight = 70,
  control = list(seed = 99),
  initial = list(ka = 1.5, cl = 3.2, v = 32,
    eta_ka_var = 0.25, eta_cl_var = 0.36, residual_sd = 0.7)
)
attr(fit_alternative, "allometry")$initial # all six resolved starts
fit_alternative$theta                    # fitted backend parameters
```

These example values are illustrative, not recommended for arbitrary drugs or
units. Choose starts using the study's model and units, then compare convergence,
parameter estimates, objective values and diagnostics across prespecified
starts and seeds. Identical seeds do not guarantee the same fitted solution
from different starts. The wrapper performs one fit per call; it does not
search over starts, select a best fit, or establish global convergence.

If changing the reference from `old_reference` to `new_reference` while
preserving the same starting concentration curve, multiply initial `cl` by
`(new_reference / old_reference)^0.75` and initial `v` by
`new_reference / old_reference`. Other starts stay unchanged. Simply changing
the reference while keeping the same numeric clearance and volume changes
the starting model. Changing weight and reference together to a common new
weight unit leaves their ratio unchanged.

## Required event records

Use a data frame with unique, nonempty names. The four selected columns default
to response `DV`, subject `ID`, time `TIME`, and the explicitly supplied weight
name. Names are literal, may contain spaces or punctuation, and must be distinct
from each other and from `EVID`, `AMT`, and `CMT`.

| Column | Accepted values |
| --- | --- |
| Subject | Finite numeric positive integers within R's integer range; at least two subjects. |
| Time | Finite nonnegative numeric values on every record. The backend may reorder events. |
| Weight | Finite positive numeric values, exactly constant within each subject across all records. The weight/reference ratio must also be positive and finite. |
| `EVID` | Required uppercase column: 0 for observations, 1 or 101 for oral bolus doses. Both dose codes are normalized to 1. |
| `AMT` | Required uppercase column: finite positive dose amounts, zero on observations. |
| Response | Real numeric and finite on observations. Dose responses may be missing and are set to zero in backend data. Infinite responses are rejected on all rows. |
| `CMT` | Optional: 1 for dosing into the absorption compartment, 2 for central-compartment observations. Inferred if absent. |

Each subject must have at least one dose and two observations. These minimum
checks do not guarantee an informative sampling design. Multiple doses must
be explicit rows; the model adds their contributions. Input data are not
modified and no observation is silently dropped by preprocessing.

`RATE`, `DUR`, `II`, `ADDL`, `SS`, `MDV`, `CENS`, `LIMIT`, and `DVID` columns are
rejected, case-insensitively, even if their values are zero. Infusions,
implicit additional doses, steady-state dosing, missing-observation flags,
censoring and multiple endpoints need a different model interface. Other
unselected columns are ignored. Remove a modifier column only after confirming
that its semantics are absent from the data; dropping a flag is not a valid
conversion of unsupported events.

## Native result and saved metadata

The result is a native `nlmixr2FitData` object. Attribute `allometry` stores the
reference weight, `c(cl = 0.75, v = 1)`, the complete named numeric `initial`
vector, and a `column_map` with `role`, `original`, and `model` columns. `initial`
records resolved starting values on the documented user scales, separately
from fitted estimates. Older saved fits may lack this metadata field. The backend receives only `ID`, `TIME`, `DV`, `WT`, `EVID`,
`AMT`, and `CMT`. Mapping does not overwrite similarly named unused input columns.
The reference weight is embedded as a numeric literal in the stored model.

Native fit tables may omit doses and reorder observations. Do not assign their
rows back to the original data by position. Native prediction or simulation
methods need canonical backend names and raw weight in `WT`, including dose
rows. They do not apply the wrapper's original-name mapping automatically.
The metadata and stored model survive R serialization; load the appropriate
backend before using its native methods after restoring a fit. This wrapper
adds no general prediction or simulation API.

## Numerical references and limits of the evidence

For a single oral dose \(D\) at zero, with zero subject effects,
\(k_e=CL/V\), and \(k_a\ne k_e\), the closed-form concentration is

\[
C(t)=\frac{D k_a}{V(k_a-k_e)}
       \left(e^{-k_e t}-e^{-k_a t}\right),\qquad t\ge0.
\]

With \(D=100\), \(k_a=2\), reference \(CL=4\), reference \(V=20\), and weight
and reference both 70, the fixed targets are:

| Time | Concentration |
| --- | ---: |
| 0.5 | 2.983099871469540 |
| 1 | 3.796641499118717 |
| 2 | 3.622246706371695 |
| 4 | 2.494408341607328 |

The [tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-allometric.R)
compare the compiled backend model with this independently evaluated equation
at weights 35, 70 and 140 (tolerance `1e-8`). They also verify:

- Reference changes with corresponding clearance/volume reparameterization,
  and common changes of weight/reference units, preserve concentrations.
- Subject effects change absorption and clearance as specified; volume keeps
  its weight scaling without a random effect.
- A second explicit dose adds its delayed single-dose contribution.
- Compiled initialization matches the supplied log parameters, diagonal
  variances and residual SD, with every parameter free to be estimated.
  Omitted starts reproduce the original initialization exactly.
- Starting concentrations, solved without overriding backend parameters, match
  the same fixed targets; adjusting starts for a new reference preserves them.
- Saved model specifications retain their reference, starts and predictions.
- Real SAEM fits with default and custom starts on `theo_sd` retain their
  resolved starts separately from fitted estimates. Each fit's
  population predictions match evaluation of the fitted stored model with
  zero subject effects (tolerance `1e-6`).

These are structural concentration references and software integration checks.
They do not fix stochastic fitted parameter estimates, prove parameter
recovery or confidence-interval coverage, or validate arbitrary event designs.
The optional-backend tests skip when the backend is absent; the all-Suggests
CI job installs and exercises it. See the [support policy](api-support-policy.md)
and [limitations](limitations.md).
