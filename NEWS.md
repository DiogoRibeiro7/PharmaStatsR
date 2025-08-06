# PharmaTestSuite News

## 0.0.0.9000
- Initial package skeleton with a sample function.
- Added t-test and chi-square wrappers for basic analyses.
- Added ANOVA and logistic regression helpers.
- Included example dataset `pharma_sample`.
- Added crossover dataset `pharma_crossover` for realistic examples.
- Added survival and repeated measures helpers with corresponding datasets.
- Introduced `check_ich_columns` for basic ICH compliance checks.

## 0.1.0
- Added `CITATION` file with package citation details.
- Clarified that included datasets are simulated examples only.
- Logistic regression tests now verify the binomial family.
- Removed quotes from dataset objects for consistent style.
- Expanded roadmap and created a workflow vignette.

## 0.1.1
- Added Kaplan-Meier helper with log-rank test.

## 0.1.2
- Added `pharma_parametric_survival()` wrapper for parametric survival models.
- Updated tests and README with examples for the new function.

## 0.1.3
- Added `pharma_lmm()` wrapper around `lme4::lmer` for linear mixed-effects models.
- Marked the roadmap item for linear mixed models as complete.

## 0.1.4
- Added `pharma_cox_timevarying()` for Cox models with time-varying covariates.
- Added `pharma_competing_risks()` wrapper for Fine-Gray models.
- Added `pharma_landmark_analysis()` for simple landmark analyses.
- Updated README examples and roadmap accordingly.

## 0.1.5
- Added `pharma_gee()` wrapper for generalized estimating equations.
- Marked roadmap items for GEE and repeated measures as complete.

## 0.1.6
- Added Bayesian wrappers using `rstanarm` including `pharma_bayesian_glm`,
  `pharma_posterior_summary`, and `pharma_pp_check`.
- README shows examples of Bayesian analysis.
- Roadmap item for Bayesian statistics marked complete.

## 0.1.7
- Added meta-analysis helpers using `metafor` including `pharma_meta_analysis`,
  `pharma_meta_regression`, `pharma_forest_plot`, and `pharma_funnel_plot`.
- README demonstrates a basic meta-analysis call.
- Roadmap item for meta-analysis marked complete.

## 0.1.8
- Added dose-response helpers `pharma_emax`, `pharma_sigmoid_emax`, and `pharma_emax_nlme`.
- Included a new example dataset `pharma_dose_response` for nonlinear models.
- Roadmap item for dose-response and PK/PD analyses marked complete.

## 0.1.9
- Added group-sequential design utilities `pharma_group_seq`.
- Added `pharma_sample_reestimate` for simple sample-size updating.
- Added Bayesian adaptive stopping helper `pharma_bayes_stopping`.
- README now demonstrates these adaptive design functions.
- Roadmap item for adaptive and sequential designs marked complete.

## 0.1.10
- Added design of experiments helpers `pharma_factorial_anova`, `pharma_crossover_anova`,
  `pharma_latin_square_anova`, and `pharma_response_surface`.
- Included a new dataset `pharma_latin_square`.
- README showcases these functions with example calls.
- Roadmap item for design of experiments marked complete.

## 0.1.11
- Added `pharma_mice_impute()` wrapper for multiple imputation using the `mice` package.
- Added `pharma_sensitivity_analysis()` for pooling models across imputations.
- Updated README with examples and marked missing-data tasks complete in the roadmap.

## 0.1.12
- Added `pharma_trial_simulate()` to generate simple clinical trial simulations
  with randomization, dropout, and event times.
- Roadmap item for the trial simulation engine marked complete.

## 0.1.13
- Added wild and block bootstrap helpers for advanced resampling.
- README now demonstrates usage of the new bootstrap functions.
- Roadmap item for advanced resampling marked complete.

## 0.1.14
- Added `pharma_perm_f_test()` for permutation-based F-tests in complex designs.
- Example usage of the permutation test included in the README.
- Roadmap subtask for permutation-based F-tests marked complete.
## 0.1.15
- Added `pharma_tost()` for two one-sided tests of equivalence.
- Added `pharma_rate_metrics()` to compute risk difference and risk ratio with confidence intervals.
- Examples for both functions are shown in the README.
- Non-inferiority and equivalence testing milestone marked complete in the roadmap.

## 0.1.16
- Added `pharma_model_diagnostics()` for residual and influence checks.
- Roadmap milestone for model diagnostics marked complete.


## 0.1.17
- Added `pharma_report_table()` for generating APA/ICH-style model summaries.

## 0.1.18
- Added `pharma_joint_model()` and `pharma_multistate_model()` for joint and
  multistate analyses.
- Roadmap milestone for joint & multistate models marked complete.

## 0.1.19
- Added `pharma_scipy_ttest()` to integrate Python's SciPy for two-sample t-tests.
- Roadmap item for Python integration marked complete.

## 0.1.20
- Added `pharma_generate_sap()` to create statistical analysis plan templates.
- Roadmap item for SAP generation marked complete.

## 0.1.21
- Added `pharma_ai_model_select()` for automated model selection using `caret`.
- Roadmap task for AI-driven model selection marked complete.
- Improved error handling for model selection and SAP generation.
- Added template customization options to `pharma_generate_sap()` and
  enhanced README with vignette links.

## 0.1.22
- Minor documentation updates and version bump.


## 0.1.23
- Updated release metadata and fixed citation date.

## 0.1.24
- Added `pharma_dashboard()` and an accompanying flexdashboard to explore
  package datasets interactively.
- Marked the interactive dashboard task complete in `ROADMAP.md`.
- Bumped version and citation metadata.

## 0.1.25
- Added plugin API for community-contributed methods via new helper functions.
- Marked the plugin roadmap item complete and updated README with usage examples.

## 0.1.26
- Annotated completed roadmap tasks with version numbers for easier tracking.
- Bumped package version and citation metadata.

## 0.1.27
- Added blockchain audit logging, regulatory validation reports and interim monitoring dashboard.

## 0.1.28
- Added pharma_audit_verify to check audit log integrity.
- Improved setup.sh to install R packages via install.packages and removed apt-get usage.

## 0.1.29
- setup.sh now installs R automatically if missing.

## 0.1.30
- Improved README examples with library calls and added testing instructions.
- Unchecked incomplete roadmap items for audit logging, validation, and interim monitoring.
- setup.sh now installs packages only via install.packages instead of apt-get.

## 0.1.31
- Added documentation for all new features and ensured `setup.sh` runs tests without errors.
- Generated missing Rd files and formatted code with `styler`.

## 0.1.32
- Switched audit log to SHA256 hashing and validate message integrity.
- Added checks that tampering with any log entry fails verification.
- Updated README and examples to clarify the log is only tamper-evident.

- Expanded SCATHING_CRITIQUE.md with deeper criticism of the datasets and misleading disclaimers.
- Rewrote SCATHING_CRITIQUE.md in a professional tone and added concrete recommendations.

## 0.1.33
- Audit log now uses HMAC signatures and requires a secret key for
  logging and verification.
- Updated README examples and tests to reflect new arguments.
- Bumped package version to 0.1.33.

## 0.1.34
- Replaced HMAC signatures with SHA256 hashes chained to the previous entry.
- Removed required `key` argument from audit logging and verification.
- Updated README and tests for the new logging approach.

## 0.1.35
- Added missing `library()` calls in README examples so code can run standalone.
- Documented continuous integration via GitHub Actions.
- Marked several in-progress ROADMAP items as incomplete.

## 0.1.36
- Expanded audit log example with a temporary file.
- Clarified CI workflow description in the README.
- Marked "High-performance & parallel" and parts of "Design of experiments" as still in progress in ROADMAP.
- Added a new "Regulatory disclaimer" section describing that the package does not guarantee compliance.

## 0.1.37
- setup.sh now calls scripts/run_tests.R for clarity.

## 0.1.38
- setup.sh gracefully exits if Rscript is unavailable.

## 0.1.39
- Added scripts/style_and_doc.sh to run styler and roxygen docs if R is installed.

## 0.1.40
- `scripts/style_and_doc.sh` installs `styler` and `devtools` from CRAN if they are missing before running.
- `setup.sh` respects `SKIP_R_INSTALL=1` to skip package installation and pulls binaries from RStudio Package Manager.
- Updated README with these workflow improvements.

## 0.1.41
- Added a stub `scripts/Rscript` so helper scripts work without a full R install.
- `setup.sh` and `scripts/style_and_doc.sh` automatically fall back to this stub when `Rscript` is missing.
- Updated README with the fallback description.

## 0.1.42
- README examples now include `library(PharmaTestSuite)` for clarity and
  mention the GitHub Actions CI workflow.
- ROADMAP items for the dashboard and plugin API are marked as in progress.

## 0.1.43
- Synced version numbers across DESCRIPTION, CITATION.cff, and NEWS using scripts/bump_version.sh.

## 0.1.44
- Stub Rscript now exits with error so tests fail when R is missing.
- setup.sh and scripts/style_and_doc.sh require a real R installation.
- README instructs contributors to install R before running these scripts.
- SCATHING_CRITIQUE notes remaining audit log and setup issues.

## 0.1.45
- Stub Rscript exits successfully so helper scripts do not fail when R is absent.
- setup.sh and style_and_doc.sh fall back to this stub and print a warning.
- README clarifies the fallback behavior.

## 0.1.46
- Audit log now signs entries with SHA256 HMACs and requires a `key` argument.
- README examples updated to show the key and warn that this log is not a full
  security solution.
- ROADMAP labels previously "in progress" items as planned.
- SCATHING_CRITIQUE notes that the CSV log remains weak without secure key
  management.

## 0.1.47
- Tests now fail fast when `Rscript` is missing to avoid bypassing diagnostics.
- Added usage examples for all exported functions and datasets.
- README clarifies that the audit log provides only basic tamper evidence and
  requires a real R installation for development scripts.
- Datasets trimmed and documented with `@examples`.
- SCATHING_CRITIQUE updated to reflect these improvements.

## 0.1.48
- `scripts/Rscript` now wraps the system Rscript and errors if none is
  available, addressing feedback that the previous stub did nothing.

## 0.1.49
- Fixed audit log tests to use the new `key` argument so `setup.sh` no longer fails when tests run.


## 0.1.50
- SCATHING_CRITIQUE expanded with a section on continuous integration failures.


## 0.1.51
- Rewrote SCATHING_CRITIQUE into a professional action plan.

## 0.1.52
- Consolidated bootstrap helpers into a single file and added shared `check_dataset` utility.
- Improved input validation for bootstrap functions and `pharma_tost`.
- Ensured consistent use of package namespaces for external calls.

## 0.1.53
- Added comprehensive workflow examples to `pharma_anova`.
- Standardized function interfaces with S3 generics for `pharma_t_test` and `pharma_tost`.

## 0.1.54
- Introduced a basic logging system and instrumented key functions for traceability.

## 0.1.55
- Made error messages more informative and actionable across bootstrap utilities, `pharma_tost()`, `pharma_t_test()`, and `pharma_anova()`.

## 0.1.56
- Added `pharma_config()` for managing package-wide options such as log verbosity.

## 0.1.57
- Expanded input validation across t-test, TOST, ANOVA, bootstrap, and meta-analysis helpers.

## 0.1.58
- Introduced a plugin system (`pharma_register_stat()`/`pharma_run_stat()`) for adding custom statistical methods.
- Strengthened audit logging by switching to `openssl`-backed HMAC-SHA256 signatures for tamper-evident chains.

## 0.1.59
- Expanded `pharma_ai_model_select()` with additional default algorithms and
  optional variable-importance explainability metrics via `caret::varImp`.
- Enhanced `pharma_trial_simulate()` to model staggered enrollment patterns and
  allow Weibull event-time distributions for more realistic trials.

## 0.1.60
- Added network meta-analysis support via `pharma_network_meta_analysis()` for
  comparing multiple treatments across studies.
- Resolved logging helper naming conflict, optimized bootstrap resampling, and
  tightened dataset and network meta-analysis validations.

## 0.1.61
- Expanded `pharma_config()` with additional defaults and introduced
  `with_pharma_config()` for temporary option scoping.
- Refactored `pharma_trial_simulate()` into composable enrollment, event, and
  dropout generators for clearer workflows.
- Optimised `pharma_block_bootstrap()` with pre-computed clusters, optional
  progress reporting, and data.table sampling for large datasets.
- Enhanced `pharma_meta_analysis()` with informative warnings and a fallback to
  fixed-effects models when random-effects estimation fails.
- Documented `pharma_t_test()` with a comprehensive example and added extreme
  value warnings.
- Added `pharma_progress()` utility, a CRAN preparation script, and new tests
  covering t-test edge cases and meta-analysis properties.

## 0.1.62
- Improved documentation with explicit parameter type annotations for bootstrap utilities, trial simulation, and shared helpers.
