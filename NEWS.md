# PharmaStatsR News

## Unreleased
- Correct the bundled crossover example to balanced AB/BA treatment sequences, encode subject and period as factors, and require a complete balanced two-period allocation in `pharma_crossover_anova()`. Previous A/A versus B/B example fits confounded treatment with subject; numeric design IDs now require explicit `factor()` conversion. Recheck earlier results.
- Fit Latin square row and column effects as categorical blocks in the bundled example, and require a complete, balanced allocation before `pharma_latin_square_anova()` fits. Numeric design IDs now require explicit `factor()` conversion; recheck earlier results that used numeric IDs or incomplete squares.
- Restrict `pharma_anova()` to one categorical group with an intercept, and fit against the original data so `factor(dose)` and other formula transformations work. Numeric group codes now require explicit `factor()` conversion; earlier numeric-predictor results may have tested a linear trend rather than group mean equality.
- Resolve `pharma_gee()` cluster identifiers within the input data, reject missing or interleaved cluster records, and test against direct `geepack::geeglm()` with the optional backend installed in CI. The documented `id = subject` call now works; recheck earlier GEE fits if identifiers or rows may have been misaligned.
- Reject missing response or group values in the formula interfaces of `pharma_t_test()` and `pharma_anova()` instead of silently dropping incomplete rows before validation. Review previous analyses with missing model variables.
- Route Kaplan–Meier curve options only to `survfit()`, share row selection, missing-value handling and default near-tie correction with the log-rank test, and reject settings that would produce mismatched curve/test analyses. Reject `timefix = FALSE` for paired analyses, because the log-rank backend cannot consistently accept an explicit value. Check boolean controls and right-censored responses; callers who passed `subset` should use an explicit logical subset and review earlier paired outputs.
- Use the fitted observation count for model-diagnostic Cook's-distance screening, validate the standardized-residual threshold, and allow an explicit Cook cutoff. Preserve missing flags from `na.exclude` fits and clarify that screening flags require interpretation rather than establishing outliers.
- Make audit-log verification reject malformed or altered CSV records with `FALSE`, restore valid-chain coverage, and refuse to append to a log that fails verification or uses a different key. Clarify that local HMAC chaining cannot detect deletion of final records without an external checkpoint.
- Fix `pharma_competing_risks()` to pass original competing-event codes to `cmprsk::crr()` and retain every predictor from no-intercept formulas. Reject missing or nonfinite model inputs; recompute earlier competing-risks analyses because censoring and event types may have been misclassified.
- Clarify that `pharma_parallel_bootstrap()` resamples independent rows, not clusters. Enable future-safe random streams for reproducible seeded runs across backends, validate replicate counts, preserve caller plans, and test the optional future backend in CI. Recompute previously generated parallel draws when reproducibility matters.
- Correct `pharma_block_bootstrap()` to accept character ID vectors, ignore unused factor levels, and use consistent base data frames. Add optional `resample_id` to distinguish repeated cluster copies, validate design inputs, and leave missing non-ID values for the statistic to handle. Recompute results based on factor IDs with unused levels or grouped models that merged repeated copies.
- Fix `pharma_wild_bootstrap()` to keep the original model frame, including transformed terms and offsets, reject missing model values and noninteger replicate counts, and require an identifiable model. Coefficient draws from earlier calls with formula offsets or silently omitted rows must be recomputed.
- Validate two-arm trial simulation inputs, support zero event and dropout rates, and clarify that Weibull event parameters are cumulative hazard coefficients rather than constant hazards. Correct the simulator's roxygen attachment and document randomization and censoring semantics.
- Correct `pharma_perm_f_test()` to test the whole linear model rather than the first sequential ANOVA term, keep analysis rows fixed across permutations, validate inputs, and document response exchangeability. Remove the misleading repeated-measures example and recompute earlier permutation results.
- Correct the description of `pharma_bayes_stopping()` as a single-arm response-rate threshold, allow a configurable `null_rate`, validate beta shapes/counts/cutoffs, and compute very small posterior tail probabilities without subtraction. Previous `prob` results at the default benchmark are unchanged except for numerical accuracy; `trials = 0` is now rejected.
- Correct `pharma_sample_reestimate()` to return a balanced two-arm total based on the within-arm variance, validate inputs, and document that it is a normal-approximation planning calculation rather than a calibrated interim adaptation. Recompute prior totals.
- Replace `pharma_rate_metrics()` Wald difference intervals with Newcombe intervals and use half-count adjusted log ratio intervals, including zero-event groups. Risk ratio is now undefined (`NA`) when both groups have zero events. Validate whole-number counts and confidence levels; recompute previously reported intervals.
- Replace uncalibrated group-sequential threshold formulas with gsDesign's two-sided O'Brien-Fleming and Pocock boundaries; earlier `pharma_group_seq()` results must be recomputed.
- Replace the misleading `compliant` result in `pharma_validation_report()` with `columns_present`; add `pharma_column_report()` and `pharma_check_columns()` for explicit column-only checks. Update callers that read `$compliant`.
- Align the documentation with the shared dark-first design, including a responsive landing page, light-mode toggle, and mathematical notation.
- Add a dark documentation site with installation, method, equivalence, and validation guides and check it on pull requests.
- Document public installation and prepare GitHub Pages deployment from `main`.
- Keep the Rd manual within page width and use a convergent counting-process fixture for the Cox model test.
- Repair R CMD check failures in examples, documentation, and statistical tests; use repeated subject measurements in the mixed-effects Emax example data.
- Rename the R package from PharmaTestSuite to PharmaStatsR; reinstall from the new repository URL and update package load and citation calls.
- Correct Welch TOST degrees of freedom, reject undefined variance and missing observations, and register both S3 methods.
- Run package tests during pull request checks and correct dependency metadata.
- Restore test files to the package build; improve contributor and security guidance.
- Replace invalid optional-backend examples with accurate usage notes.

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
- Refined documentation with explicit type annotations across bootstrap helpers, utilities, and trial simulation; internal simulation steps are now documented.
- Added CRAN preparation roadmap.
- Expanded roadmap with an extended long-term vision section.
- Introduced `validate_inputs()` for centralized data and formula checks and applied it to `pharma_t_test()`.
- `pharma_anova()` and `pharma_kaplan_meier()` now call `validate_inputs()` for
  consistent argument checking, and the Kaplan-Meier helper verifies that the
  `survival` package is installed before execution.
- `pharma_tost()`'s formula method now uses `validate_inputs()` for consistent
  data and formula validation.
- `pharma_lmm()` now validates its inputs and confirms that the `lme4` package
  is available before fitting models.
- `pharma_competing_risks()` now validates inputs and confirms that the `cmprsk`
  package is installed before fitting models.
- Added tests for optional dependencies (e.g., geepack, cmprsk, survival, nlme, mice, openxlsx, reticulate) and updated the setup script to install them, enabling positive-path coverage.
- Added tests covering `validate_inputs()` and ensuring key helpers error on
  invalid datasets or formulas.
- Extended input validation tests to check that helpers reject non-data-frame
  inputs.
- Added tests for configuration utilities, Bayesian posterior checks, Python SciPy bridge, plugin statistics, response-surface modeling, report table exports, joint and multistate model guards, and logging/progress helpers to improve coverage.
- `pharma_gee()` now validates inputs, requires `geepack` at runtime, and both `geepack` and `lme4` were moved to Suggests for softer dependencies.
- Meta-analysis helpers now check for `metafor`/`netmeta` at runtime and
  `pharma_network_meta_analysis()` reuses `validate_inputs()`; both packages
  were moved to Suggests.
- README now highlights the project's motivation.
