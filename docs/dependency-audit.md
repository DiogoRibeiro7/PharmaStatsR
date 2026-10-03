# Dependency and optional backend audit

Issue [#53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53) tracks the remaining audit. `scripts/check_dependency_metadata.R` parses namespace-qualified calls in `R/` and rejects packages absent from `DESCRIPTION`; the package check runs it on every PR. This ledger also records runtime dependencies that are discovered by name rather than called with `pkg::fun`.

## Required packages

| `DESCRIPTION` tier | Packages | Use |
| --- | --- | --- |
| `Imports` | `stats`, `utils`, `parallel`, `survival`, `nlme`, `broom`, `gsDesign` | Statistics and data helpers; survival models; mixed Emax; tidy model tables; sequential designs. These are installed with the package. |
| `Suggests` for checks and builds | `testthat`, `knitr`, `rmarkdown` | Tests and the vignette toolchain. `rmarkdown` also launches the example dashboards. |

The development script `./setup.sh` installs its own test tools through `scripts/run_tests.R`. It no longer treats `openssl`, a Suggested runtime backend, as a prerequisite for the local test command. Tests for optional paths skip the available-backend case when the backend is absent; deterministic missing-backend tests should run regardless of what CI installed.

## Suggested runtime packages

| Packages | Entry points or runtime use | Current missing-path evidence |
| --- | --- | --- |
| `rstanarm`, `bayesplot` | Bayesian GLM, posterior summary, and predictive check | Deterministic guards cover both dependencies of predictive checking: `rstanarm` registers the `stanreg` method and `bayesplot` provides the generic. An installed fit, summary, and predictive plot run in the all-Suggests matrix. |
| `lme4`, `geepack`, `cmprsk` | Mixed models, GEE, and competing risks | Deterministic guard tests; installed fits have separate tests where the backend is present. |
| `future`, `future.apply` | Row bootstrap and future plan | Both missing paths are forced in tests; installed sequential and multisession cases compare seeded draws. |
| `openssl` | Local audit log and verification | Both missing paths are forced in tests; the installed HMAC chain has separate tests. |
| `caret`, `mice`, `metafor`, `netmeta`, `JM`, `mstate` | Model selection, imputation, meta-analysis, joint and multistate models | All `metafor` public entry points now have forced missing-backend tests. Other functions have missing and installed cases; complete function-by-function reconciliation remains under #53. |
| `reticulate` | Python SciPy t-test bridge | Missing R and Python module tests and an installed SciPy comparison are in the PR check; Python SciPy is installed separately and is not an R `DESCRIPTION` dependency. |
| `openxlsx`, `flextable`, `officer` | Optional Excel and Word output | Missing exporter guards and installed file-content tests. |
| `rmarkdown`, `flexdashboard`, `shiny` | Launch bundled example dashboards | Missing launch dependencies are forced in tests; retrieving the bundled path needs none of them. |

The [routine PR checks](development.md#package-checks) include a required-dependencies job alongside the selected-backend job. The former checks installation, examples, and tests with no optional modeling or reporting backend installed explicitly; the latter exercises its named installed backends and deterministic missing paths. The separate all-Suggests matrix runs on a schedule or by request. A passing routine PR check does not cover every Suggested package's available path. `caret` may also request model engines not declared here, according to the caller's chosen methods.
