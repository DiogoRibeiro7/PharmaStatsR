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
| Screening | `screen_covariates_stepwise()`, `screen_covariates_bayesian()`, `screen_covariates_lasso()` | AIC stepwise, univariate BIC scores, and Gaussian penalized regression; these are not mixed-effects selection procedures. |
| Models | `prepare_model_matrix()`, `fit_covariate_model()` | Design matrix construction and a linear `nlme` model with a random subject intercept. |
| Nonlinear example | `fit_nlmixr_model()` | Fixed one-compartment SAEM example; dose records are required. Supplied covariates are checked but ignored with a warning. |
| Repeated measurements | `reshape_timevarying()` | Explicit mapping of wide covariate/time columns to long data, preserving literal names. |
| Plots | `plot_obs_vs_pred()`, `plot_residuals()`, `plot_vpc()` | Observed/fitted and residual plots; `plot_vpc()` is a descriptive binned summary, not a simulation-based predictive check. |
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
  joint Bayesian model.
- LASSO supports numeric candidates and subject-grouped or explicit folds.
  Grouping holds out subjects; preprocessing is not refitted within each fold.
  Perform data splitting before estimating preprocessing for model evaluation.
- Euclidean distance retains predictor units and categorical factor codes.
  Gower uses observed-range scaling and available-pair weighted averages.
  Predictor weights affect donor selection; selected donors contribute equally
  to the imputed mean or mode. Earlier targets can influence later targets.
- Native mixed-model fitting still requires supported column names. Automatic
  imputation recipes, categorical encoding recipes, covariate-aware nonlinear
  models, and simulation-based predictive checks remain future work.
- The diagnostics app fits `DV` by `Time` with a random subject intercept.
  Reactive server tests cover upload, fitting, rendering, and recovery; they do
  not establish browser accessibility or usability.

## Dependencies and installed resources

`glmnet`, `tidyr`, `ggplot2`, and `tidyselect` join the required dependencies for
screening, reshaping, and plots. The existing `nlme` import supports the linear
mixed-model wrapper. Optional integrations stay optional:

- `shiny` runs the diagnostics app.
- `rmarkdown` and `knitr`, with Pandoc, render reports; PDF needs LaTeX.
- `broom.mixed` optionally tidies report coefficients; the template retains its
  native `nlme` summary fallback.
- `nlmixr2est` fits the fixed nonlinear example; `nlmixr2data` supplies its example
  data. `cluster` supplies independent Gower reference tests, not the imputation
  implementation.

The report uses the installed `templates/covariate-report.Rmd` resource. A
standalone launcher is installed at `shiny/covariate_diagnostics_app.R`;
`run_diagnostics_app()` remains the public entry point. Generated HTML reports
from the old repository are not shipped as input data.

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
