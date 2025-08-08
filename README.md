# PharmaTestSuite

[![R-CMD-check](https://github.com/DiogoRibeiro7/PharmaTestSuite/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DiogoRibeiro7/PharmaTestSuite/actions/workflows/R-CMD-check.yaml)

PharmaTestSuite provides statistical test utilities tailored for the pharmaceutical industry. The package aims to simplify the design and execution of common analysis workflows and includes helpers for basic regulatory compliance checks.

## Motivation

Pharmaceutical statisticians often juggle a patchwork of R packages with inconsistent interfaces and limited validation. PharmaTestSuite was created to provide a unified, well-tested toolkit that streamlines analyses, promotes reproducibility, and lowers the barrier to regulatory-minded practice. By wrapping common methods and bundling helpers for logging, auditing, and configuration, the suite delivers a single home for routine clinical research tasks.

All changes are checked automatically via GitHub Actions, which runs the full test suite on every commit.

## Installation

PharmaTestSuite is not yet available on CRAN. You can install the development version from GitHub:

```r
# install.packages("devtools")
# devtools::install_github("DiogoRibeiro7/PharmaTestSuite")
```

## Example

```r
library(PharmaTestSuite)
library(survival)
library(lme4)
pharma_greeting()

# built-in datasets
data(pharma_sample)
data(pharma_crossover)
data(pharma_survival)
data(pharma_repeated)
data(pharma_dose_response)

pharma_t_test(rnorm(10), rnorm(10))
pharma_chisq_test(matrix(c(10,5,6,9), nrow=2))
pharma_anova(response ~ treatment, data = pharma_sample)
pharma_logistic_regression(outcome ~ dose, data = pharma_sample)
pharma_emax(pharma_dose_response$dose, pharma_dose_response$response)
pharma_sigmoid_emax(pharma_dose_response$dose, pharma_dose_response$response)
pharma_survival_fit(survival::Surv(time, status) ~ treatment, data = pharma_survival)
pharma_parametric_survival(survival::Surv(time, status) ~ treatment,
                          data = pharma_survival,
                          dist = "weibull")
pharma_cox_timevarying(Surv(start, stop, status) ~ treatment,
                       data = pharma_survival)
pharma_competing_risks(Surv(time, status) ~ treatment,
                       data = pharma_survival)
pharma_landmark_analysis(Surv(time, status) ~ treatment,
                         data = pharma_survival,
                         landmark = 12)
pharma_group_seq(k = 4)
pharma_sample_reestimate(50, 0.4, 1)
pharma_bayes_stopping(1, 1, 8, 10)
pharma_factorial_anova(response ~ treatment * dose, data = pharma_sample)
pharma_crossover_anova(response ~ treatment + period + subject, data = pharma_crossover)
pharma_latin_square_anova(response ~ treatment + row + column, data = pharma_latin_square)
pharma_response_surface(pharma_dose_response$dose, pharma_dose_response$dose, pharma_dose_response$response)
sim <- pharma_trial_simulate(100)
head(sim)
meta_res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1),
                                vi = c(0.05, 0.04, 0.06))
pharma_forest_plot(meta_res)
pharma_repeated_anova(response ~ condition + Error(subject), data = pharma_repeated)
pharma_lmm(response ~ condition + (1|subject), data = pharma_repeated)
pharma_gee(response ~ condition, id = subject, data = pharma_repeated)
fit <- pharma_bayesian_glm(outcome ~ dose, data = pharma_sample, iter = 500, chains = 2)
pharma_posterior_summary(fit)
if (requireNamespace("bayesplot", quietly = TRUE)) {
  pharma_pp_check(fit)
}
check_ich_columns(pharma_sample)
if (requireNamespace("mice", quietly = TRUE)) {
  dat_na <- pharma_sample
  dat_na$response[1] <- NA
  imp <- pharma_mice_impute(dat_na, m = 2, maxit = 1)
  pharma_sensitivity_analysis(imp, response ~ treatment)
}
wild <- pharma_wild_bootstrap(response ~ treatment, data = pharma_sample, R = 10)
block_stat <- function(d) mean(d$response)
pharma_block_bootstrap(pharma_sample, "subject", block_stat, R = 10)
pharma_perm_f_test(response ~ treatment * period, data = pharma_crossover, R = 50)
pharma_tost(rnorm(30), rnorm(30, 0.1), -0.5, 0.5)
pharma_rate_metrics(10, 100, 12, 110)
pharma_report_table(lm(response ~ treatment, data = pharma_sample))
pharma_scipy_ttest(rnorm(20), rnorm(20))
pharma_generate_sap(objectives = "Assess efficacy and safety")
# Customize the SAP with additional sections
pharma_generate_sap(
  objectives = "Assess efficacy",
  endpoints = "Overall survival",
  extra_sections = list(Timeline = "Visit schedule"),
  include_sections = c("Objectives", "Endpoints", "Planned Analyses")
)
pharma_ai_model_select(
  response ~ treatment,
  data = pharma_sample,
  models = c("glm", "rf", "svmLinear"),
  metric = "Accuracy"
)

pharma_joint_model(lme_fit, cox_fit, timeVar = "time")
pharma_multistate_model(cox_ms, trans_matrix)


pharma_dashboard(launch = FALSE)
```

```r
# Register a custom plugin
library(PharmaTestSuite)
my_summary <- function(x) mean(x)
pharma_register_plugin("avg", my_summary)
pharma_run_plugin("avg", 1:10)
pharma_list_plugins()
pharma_unregister_plugin("avg")
```

- `pharma_audit_log()` records analysis steps using SHA256 HMAC signatures chained to the previous entry. This provides only basic tamper evidence.
- `pharma_audit_verify()` recomputes these HMACs to detect tampering.
- `pharma_validation_report()` checks a dataset for required columns.
- `pharma_interim_dashboard()` launches a simple Shiny dashboard.

```r
# Audit logging helpers
library(PharmaTestSuite)
tmp <- tempfile()
pharma_audit_log("Loaded data", tmp, key = "secret")
pharma_audit_log("Fit model", tmp, key = "secret")
pharma_audit_verify(tmp, key = "secret")
pharma_validation_report(pharma_sample, "Treatment effect")
pharma_interim_dashboard(launch = FALSE)
This log provides only basic tamper evidence. It does not guarantee full
integrity or security; for regulated use, adopt a proven audit solution.
```
**Note:** All datasets included in PharmaTestSuite are simulated examples only and should not be used to make clinical decisions. The package is intended for demonstration and educational purposes.

See `ROADMAP.md` for planned features.

Additional worked examples can be found in the vignette
[`Pharmaceutical Workflow Example`](vignettes/pharma_workflow.Rmd).
A demo dashboard can be launched with `pharma_dashboard()`.

## Parallel computation

The `pharma_parallel_bootstrap` function distributes bootstrap iterations
across multiple cores using the `future` framework.

```r
library(PharmaTestSuite)
stat <- function(d) mean(d$response)
pharma_parallel_bootstrap(pharma_sample, stat, R = 100,
                          plan = "multisession")
```

## Model diagnostics

Use `pharma_model_diagnostics()` to examine residuals and identify influential
observations in fitted models.

```r
library(PharmaTestSuite)
fit <- lm(response ~ treatment + dose, data = pharma_sample)
pharma_model_diagnostics(fit)
```

## Development and testing

Run `./setup.sh` to install any missing R packages with `install.packages()` and execute the test suite. Set the environment variable `SKIP_R_INSTALL=1` to skip package installation when compilation would take too long. Continuous integration runs the same workflow on every commit and pull request using the `R-CMD-check.yaml` GitHub Actions configuration. The action installs package dependencies and runs `devtools::test()` so that all tests must pass before code is merged.
These helper scripts require a working R installation. A small wrapper script
(`scripts/Rscript`) forwards arguments to your system `Rscript` and fails with a
clear error if none is available. This ensures tests are not bypassed. For
release preparation and CRAN checks you must have a real `Rscript` binary
installed.

## Contact

For questions or feedback, please contact Diogo Ribeiro
(<dfr@esmad.ipp.pt> or <diogo.debastos.ribeiro@gmail.com>),
ESMAD - Instituto Politécnico do Porto.
ORCID: <https://orcid.org/0009-0001-2022-7072>.

## Regulatory disclaimer

PharmaTestSuite offers convenience wrappers for common analyses but does **not**
guarantee compliance with any specific regulatory guidance. Users remain
responsible for validating methods against the official documents such as ICH
E9(R1) or FDA guidelines.

## Citation

To cite **PharmaTestSuite** in publications, please refer to the
`CITATION` file included in the package or the `CITATION.cff` metadata on
GitHub.

## Versioning

The project uses a simple helper script to update version numbers across the package metadata. Run `scripts/bump_version.sh <new-version>` to increment the version in `DESCRIPTION` and `CITATION.cff`, append a section to `NEWS.md`, commit the change, and create a matching Git tag.

## Developer utilities

Run `scripts/style_and_doc.sh` to format the R code with `styler` and refresh documentation via `devtools`. The helper installs those packages automatically if they are missing and skips everything if R is unavailable.
