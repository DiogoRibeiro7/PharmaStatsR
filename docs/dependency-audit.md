# Dependency and optional backend audit

Issue [#53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53) tracks this audit. `scripts/check_dependency_metadata.R` checks namespace-qualified calls, literal `requireNamespace()` calls, and literal calls to `.pharma_require_optional()` against `DESCRIPTION` on every PR. The table below also records packages passed through variable-name guards, which the static check cannot infer.

## Required packages

| `DESCRIPTION` tier | Packages | Use |
| --- | --- | --- |
| `Imports` | `stats`, `utils`, `parallel`, `survival`, `nlme`, `broom`, `gsDesign` | Statistics and data helpers; survival models; mixed Emax; tidy model tables; sequential designs. These are installed with the package. |
| `Suggests` for checks and builds | `testthat`, `knitr`, `rmarkdown` | Tests and the vignette toolchain. `rmarkdown` also launches the example dashboards. |

The development script `./setup.sh` installs its own test tools through `scripts/run_tests.R`. It no longer treats `openssl`, a Suggested runtime backend, as a prerequisite for the local test command. Tests for optional paths skip the available-backend case when the backend is absent; deterministic missing-backend tests should run regardless of what CI installed.

## Suggested runtime packages

The test names below are in `tests/testthat/`. Every unavailable path is forced by a mocked package check, so its assertion runs even if the backend is installed. Available-path tests use `skip_if_not_installed()` and run when their named packages are installed. The selected-backend PR job installs its [explicit package list](development.md#package-checks); the all-Suggests matrix is scheduled weekly or can be run manually.

| Packages | Exported entry points | Unavailable-path test | Available-path test and guaranteed job |
| --- | --- | --- | --- |
| `rstanarm` | `pharma_bayesian_glm()`, `pharma_posterior_summary()` | `test-optional-backend-guards.R` | `test-pharma_tests.R`; all-Suggests only. |
| `rstanarm`, `bayesplot` | `pharma_pp_check()` | `test-pp-check.R` forces each package separately. | `test-pharma_tests.R` checks a `stanreg` plot; all-Suggests only. `rstanarm` registers the method, and `bayesplot` provides the generic. |
| `lme4` | `pharma_lmm()` | `test-optional-backend-guards.R` | `test-pharma_tests.R`; all-Suggests guarantees installation. |
| `geepack` | `pharma_gee()` | `test-optional-backend-guards.R` | `test-gee.R`; selected PR job. |
| `cmprsk` | `pharma_competing_risks()` | `test-optional-backend-guards.R` | `test-competing-risks.R`; selected PR job. |
| `future`, `future.apply` | `pharma_parallel_bootstrap()` | `test-optional-backend-guards.R` forces each package separately. | `test-parallel-bootstrap-rng.R`; selected PR job. |
| `openssl` | `pharma_audit_log()`, `pharma_audit_verify()` | `test-optional-backend-guards.R` | `test-audit.R`; selected PR job. |
| `caret` | `pharma_ai_model_select()` | `test-ai-model.R` | `test-ai-model.R` checks an explicit `glm` candidate; selected PR job. |
| `mice` | `pharma_mice_impute()`, `pharma_sensitivity_analysis()` | `test-mice-backend.R` | `test-mice-backend.R`; selected PR job. |
| `metafor` | `pharma_meta_analysis()`, `pharma_forest_plot()`, `pharma_funnel_plot()` | `test-meta.R` | `test-meta-analysis.R` and `test-pharma_tests.R`; selected PR job. |
| `metafor` | `pharma_meta_regression()` | `test-meta-regression.R` | `test-meta-regression.R`; selected PR job. |
| `netmeta` | `pharma_network_meta_analysis()` | `test-netmeta-backend.R` | `test-netmeta-backend.R`; selected PR job. |
| `JM` | `pharma_joint_model()` | `test-joint-model.R` | `test-joint-model.R`; selected PR job. It also checks the backend's attachment requirement. |
| `mstate` | `pharma_multistate_model()` | `test-multistate-backend.R` | `test-multistate-backend.R`; selected PR job. |
| `reticulate`; Python SciPy | `pharma_scipy_ttest()` | `test-scipy-bridge.R` forces missing R and Python modules separately. | `test-scipy-bridge.R`; selected PR job installs SciPy through Python 3.12. SciPy is not an R `DESCRIPTION` dependency. |
| `openxlsx` | `pharma_report_table(file = "*.xlsx")` | `test-report-table.R` | `test-report-table.R` reads the saved workbook; selected PR job. |
| `flextable`, `officer` | `pharma_report_table(file = "*.docx")` | `test-report-table.R` forces each package separately. | `test-report-table.R` inspects the saved document; selected PR job. |
| `rmarkdown`, `flexdashboard`, `shiny` | `pharma_dashboard(launch = TRUE)`, `pharma_interim_dashboard(launch = TRUE)` | `test-dashboard.R` forces each package for both entry points. | `test-dashboard.R` checks path forwarding with the runner mocked; selected PR job. Retrieving a path with `launch = FALSE` needs none of these packages. |

The [routine PR checks](development.md#package-checks) include a required-dependencies job and a selected-backend job. The all-Suggests matrix verifies and logs every declared Suggested R package before running the package check, and audits source declarations on each matrix platform. A green routine PR run does not establish the `rstanarm` or guaranteed `lme4` installed paths. The dashboard tests do not open an interactive Shiny server. Record an all-Suggests run on the candidate commit under [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) before treating the optional integration evidence as release-ready. `caret` may request additional model engines for methods other than the explicitly tested `glm` candidate.
