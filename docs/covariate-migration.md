# Covariate workflows and migration from pharmoCovR

The covariate module is maintained directly in PharmaStatsR. It includes all
18 functions from pharmoCovR, its simulated `pharmo_example` dataset, regression
tests, report template, Shiny app, and five analysis vignettes. Installing or
loading pharmoCovR is not required.

The import records the original pharmoCovR commit
`b4d8c6f512103d64e5614eb19b5f0c0c6644666a`, including predictor weighting.
The standalone repository was deleted after [PR #195](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/195)
merged on 15 October 2026. The preserved implementation is available in
[PharmaStatsR commit `65bc1be`](https://github.com/DiogoRibeiro7/PharmaStatsR/tree/65bc1be17fc150e1af42eab6c2b6b33d7f167046).
The source's MIT notice is retained in
[`inst/NOTICE-pharmoCovR`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/inst/NOTICE-pharmoCovR).
Package references and resource paths were
adapted; public function names, arguments, defaults, and statistical algorithms
were preserved. [Issue #194](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/194)
tracks the consolidation. Existing PharmaStatsR exports remain available.

## Update existing scripts

Replace `library(pharmoCovR)` with `library(PharmaStatsR)`, and replace explicit
`pharmoCovR::` prefixes with `PharmaStatsR::`. Keep the original function names
and arguments. Use an explicit package when loading the simulated dataset:

```r
library(PharmaStatsR)
data("pharmo_example", package = "PharmaStatsR")

prepared <- impute_ml(
  pharmo_example, c("WT", "AGE", "CRCL"), k = 5,
  predictors = c("WT", "AGE", "CRCL"), distance = "gower",
  weights = c(WT = 2)
)
scaled <- center_scale(prepared, c("WT", "AGE", "CRCL"))
model <- fit_covariate_model(
  scaled$data, "DV", "SubjectID", c("Time", "WT", "AGE")
)
plot_obs_vs_pred(model, scaled$data)
plot_residuals(model)
```

Use explicit `PharmaStatsR::` calls if both packages are attached, because their
shared function names can mask each other. Existing local installations of
pharmoCovR are not automatically uninstalled or replaced, but the deleted
repository and its release URLs are no longer installation sources. Use
`remotes::install_github("DiogoRibeiro7/PharmaStatsR")` for the maintained package.
Source-tree paths and private functions are not part of the public migration
contract. The historical commit identifier above is attribution; the old Git
history was not imported into PharmaStatsR.

## Functions and scope

| Purpose | Functions | Scope to preserve |
| --- | --- | --- |
| Schema | `validate_data_schema()` | Unique names, integer `SubjectID`, numeric `Time`/`DV`, and at least one covariate. This is a table check, not a study-design check. |
| Imputation | `impute_mean()`, `impute_median()`, `impute_ml()` | Numeric location imputation or nearest neighbors; explicit predictors and named nonnegative weights; targets without usable donors stay missing with a warning. |
| Scaling | `center_scale()`, `apply_center_scale()` | Estimate centering/scaling parameters once and apply saved parameters to new data. |
| Saved neighbors (added after consolidation) | `fit_knn_imputation()`, `apply_knn_imputation()` | Numeric targets, mixed predictors, training-only donors and frozen Gower scales; see the [guide](fitted-knn.md). |
| Saved imputation (added after consolidation) | `fit_imputation()`, `apply_imputation()` | Save numeric training mean/median replacements and apply them to new data without refitting; see the [training-preprocessing guide](fitted-imputation.md). |
| Saved encoding (added after consolidation) | `fit_encoding()`, `apply_encoding()` | Save training levels, numeric coding, and output columns for use on new data; see the [encoding guide](fitted-encoding.md). |
| Screening | `screen_covariates_stepwise()`, `screen_covariates_bayesian()`, `screen_covariates_lasso()` | AIC stepwise, univariate BIC scores, and Gaussian penalized regression; these are not mixed-effects selection procedures. |
| Saved screening prediction (added after consolidation) | `predict_lasso_imputed()` | Apply the final saved imputer, restore predictor order, and predict at fitted penalties; see the [guide](predict-lasso-imputed.md). |
| Numeric screening with fold imputation (added after consolidation) | `screen_covariates_lasso_imputed()` | Prespecified Gaussian penalty grid; training-fold mean/median or nearest-neighbor imputation and standardization; held-out predictions and saved final parameters. See the [guide](lasso-imputation.md). |
| Models | `prepare_model_matrix()`, `fit_covariate_model()` | Design matrix construction and a linear `nlme` model with a random subject intercept; [opt-in literal-name repair](covariate-mixed-model.md). |
| Mixed-model prediction | `predict_covariate_model()` | Original-name population or subject predictions from native fits, including saved name mappings. |
| Mixed-model simulation (added after consolidation) | `simulate_covariate_model()` | Population response replicates from the fitted Gaussian random-intercept model, with parameters held fixed; see the [guide](covariate-simulation.md). |
| Weight-allometric nonlinear fitting (added after consolidation) | `fit_nlmixr_allometric()` | Prespecified oral model with subject-constant weight and fixed clearance/volume exponents; optional natural-scale starting values and saved initialization metadata. See [equations and event contract](allometric-nonlinear.md). |
| Allometric response simulation (added after consolidation) | `simulate_nlmixr_allometric()` | Population replications with fresh subject effects and additive residuals; original names and row order, fixed fitted parameters, explicit doses and seeded R draws. See the [worked guide](allometric-simulation.md). |
| Nonlinear example | `fit_nlmixr_model()` | Fixed one-compartment SAEM example; dose records are required. Supplied covariates are checked but ignored with a warning. |
| Repeated measurements | `reshape_timevarying()` | Explicit mapping of wide covariate/time columns to long data, preserving literal names. |
| Plots | `plot_obs_vs_pred()`, `plot_residuals()`, `plot_vpc()` | Observed/fitted and residual plots; `plot_vpc()` is a descriptive binned summary, not a simulation-based predictive check. |
| Simulated percentile checks (added after consolidation) | `plot_simulated_vpc()` | Observed percentiles against replicate-wise simulation bands, with numerical summaries and row/bin membership; see the [guide](simulated-vpc.md). The caller supplies complete response replicates. |
| App and reports | `run_diagnostics_app()`, `generate_report()` | CSV diagnostics with failure feedback; HTML/PDF reports with isolated rendering and explicit output paths. |

The module keeps its descriptive function names for migration compatibility.
No second set of `pharma_*` aliases is introduced. Its functions are
**experimental**, except `fit_nlmixr_model()`, which is **example-only**. The
simulated dataset is illustrative and contains no patient records. See the
[export inventory](method-inventory.md) for the tests and support level of each
function.

### Relationship to existing methods

| Existing PharmaStatsR API | Covariate API | Why both remain |
| --- | --- | --- |
| `pharma_mice_impute()` and `pharma_sensitivity_analysis()` | `impute_mean()`, `impute_median()`, `impute_ml()` | Multiple imputation and pooled inference differ from single-value imputation. Nearest-neighbor results do not quantify imputation uncertainty. |
| `pharma_lmm()` | `fit_covariate_model()` | The former accepts a general `lme4` formula; the latter uses column-name inputs and a fixed random-intercept `nlme` specification. |
| `pharma_model_diagnostics()` | Covariate plots | The former returns numerical diagnostics for unweighted `lm` fits; the latter produces plots for supported fitted models. |
| `pharma_report_table()` | `generate_report()` | A coefficient table or file export differs from a rendered model report with diagnostic plots. |
| `pharma_ai_model_select()` | Covariate screening functions | Comparing `caret` model fits differs from selecting covariates using the documented AIC, BIC, or penalized-regression rules. |

### Statistical limits

- AIC/BIC screening uses a common complete-case cohort and ordinary linear
  regression. The stepwise `id` argument is checked for presence but does not
  model correlation. BIC-based scores are not posterior probabilities from a
  joint Bayesian model. The [BIC screening guide](bic-screening.md) gives the
  independent RSS/penalty reference and the errors for saturated models or
  non-finite BIC values; invalid comparisons stop the whole call. The
  [stepwise AIC guide](aic-screening.md) traces forward additions and backward
  removal, guards accepted models, and demonstrates a local search minimum.
- `screen_covariates_lasso()` supports numeric candidates and subject-grouped or
  explicit folds, with complete-case filtering and no preprocessing hook. The
  [complete-case LASSO guide](lasso-screening.md) gives analytic coefficient/CV
  references and the correction for literal `(Intercept)` candidates. The
  separate `screen_covariates_lasso_imputed()` refits mean/median or nearest-neighbor imputation and
  standardization within training folds for a prespecified penalty grid. Its
  [`encode = TRUE` mode](lasso-encoding.md) also fits categorical encoding within
  folds and records selected raw variables and design columns. Both
  use Gaussian models and observation-weighted scoring, not mixed models.
- Euclidean distance retains predictor units and categorical factor codes.
  Gower uses observed-range scaling and available-pair weighted averages.
  Predictor weights affect donor selection; selected donors contribute equally
  to the imputed mean or mode. Earlier targets can influence later targets.
- `fit_imputation()` and `apply_imputation()` now support saved numeric mean or
  median replacements. Fit them inside each training fold, manually or through
  `screen_covariates_lasso_imputed()` for numeric screening or opt-in encoded
  designs. The separate [saved neighbor pair](fitted-knn.md)
  reuses training donors and scales for numeric targets, with no cascading
  imputations and bounded contributions for values outside training ranges.
  Numeric screening uses it within folds via `method = "knn"`; unavailable
  donors raise contextual errors rather than leaving a model matrix incomplete.
- `fit_encoding()` and `apply_encoding()` save training categorical coding and
  column order. New observed categories raise errors. Fit inside each training
  fold manually or through `screen_covariates_lasso_imputed(encode = TRUE)`.
  The latter requires observed categorical values and applies column-wise
  penalties, not grouped categorical selection.
- Mixed-model fitting keeps strict names by default; `repair_names = TRUE`
  records safe backend aliases. Use `predict_covariate_model()` for original-name
  point predictions. It defaults to population effects; unknown subjects return
  `NA` for conditional predictions. The separate [weight-allometric fitter](allometric-nonlinear.md)
  uses fixed powers of subject-constant weight in a one-compartment oral model.
  Broader nonlinear covariate specifications remain future work. `plot_simulated_vpc()` now summarizes supplied response replicates;
  their generation, subject dependence, and parameter uncertainty must be
  specified by the caller. The later `simulate_covariate_model()` supplies
  Gaussian random-intercept replications using fixed fitted parameters. It
  redraws all subject effects, including for training IDs, and excludes
  parameter uncertainty. Other model simulators remain future work.
- The [diagnostic plot guide](covariate-diagnostic-plots.md) records independent
  point/residual/percentile references. Observed/predicted plots now use actual
  predictions even when data contain `preds`; regenerate affected plots.
  Prediction and residual vectors must match their source rows without recycling.
  Binned observed and predicted summaries retain separate missing-value removal.
- The diagnostics app fits `DV` by `Time` with a random subject intercept.
  [Keyboard access and numerical alternatives](diagnostics-app.md) complement
  its plots. Server and Chromium browser tests cover upload, fitting, rendering,
  navigation, and recovery; manual assistive-technology and usability testing
  remain outside this evidence.

## Dependencies and installed resources

`glmnet`, `tidyr`, `ggplot2`, and `tidyselect` join the required dependencies for
screening, reshaping, and plots. The existing `nlme` import supports the linear
mixed-model wrapper. Optional integrations stay optional:

- `shiny` runs the diagnostics app.
- `rmarkdown` and `knitr`, with Pandoc, render reports; PDF needs LaTeX.
- `broom.mixed` optionally tidies report coefficients; the template retains its
  native `nlme` summary fallback.
- `nlmixr2est` fits the fixed nonlinear example and the weight-allometric model; `nlmixr2data` supplies their worked-example
  data. `predict_nlmixr_allometric()` also uses `nlmixr2est` to evaluate saved
  allometric fits with their original names and explicit new dosing schedules.
  [`simulate_nlmixr_allometric()`](allometric-simulation.md) adds fresh subject
  effects and residuals with fitted parameters held fixed.
  `cluster` supplies independent Gower reference tests, not the imputation
  implementation.

The report uses the installed `templates/covariate-report.Rmd` resource. A
standalone launcher is installed at `shiny/covariate_diagnostics_app.R`;
`run_diagnostics_app()` remains the public entry point. Generated HTML reports
from the old repository are not shipped as input data.

### Running the nonlinear example

The `fit_nlmixr_model()` help example performs a full SAEM fit on dosing-event
data from `nlmixr2data::theo_sd`. It uses the backend's estimation defaults and
can take more than five seconds. The help marks it with `\donttest{}`, the
[CRAN convention for lengthy examples](https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples).
Run it explicitly after installing `nlmixr2est` and `nlmixr2data`:

```r
example("fit_nlmixr_model", package = "PharmaStatsR", run.donttest = TRUE)
```

Ordinary `R CMD check` skips that block by default; the repository's
`R CMD check --as-cran` also executes examples in a separate `--run-donttest`
pass. The full-data [backend integration test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-nlmixr-helpers.R)
still fits the same dosing data and checks the fitted class, nonempty result,
and finite predictions whenever both optional packages are installed. These
checks exercise the fitting path; they do not establish parameter recovery or
model validity. The required-dependency jobs may skip this optional backend.

## Worked vignettes and evidence

PharmaStatsR contains six vignettes: the original `pharma_workflow` plus
`covariate-quickstart`, `covariate-data-preparation`, `covariate-diagnostics`,
`covariate-advanced`, and `covariate-full-workflow`. Build them when installing
from GitHub with `build_vignettes = TRUE`; see [installation](installation.md#worked-vignettes).
Then open, for example:

```r
vignette("covariate-data-preparation", package = "PharmaStatsR")
```

The imported tests are named `test-covariate-*.R`. They retain the source's
reference calculations, input boundaries, subject-fold checks, weighted Gower
comparison with `cluster::daisy()`, app server tests, and HTML/PDF rendering
checks. The package migration test also exercises the installed dataset,
preprocessing/model workflow, and resource paths under PharmaStatsR. Optional
tests skip when their backend or external renderer is absent; the all-Suggests
matrix installs the declared backends and LaTeX. Passing checks is evidence for
the tested contracts, not validation for a clinical or regulatory use case.
