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
- Added blockchain-backed audit trail helpers.
- Updated README with an example.
- Marked roadmap task complete and bumped version.

## 0.1.26
- Annotated completed roadmap tasks with version numbers for easier tracking.
- Bumped package version and citation metadata.
