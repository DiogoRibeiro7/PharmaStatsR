# PharmaStatsR

[![R-CMD-check](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml)
[![Documentation](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/docs.yml/badge.svg)](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/docs.yml)

[Documentation site](https://diogoribeiro7.github.io/PharmaStatsR/) · [Roadmap](ROADMAP.md) · [Evidence inventory](docs/method-inventory.md) · [Contributing](CONTRIBUTING.md)

PharmaStatsR brings statistical methods and covariate workflows together in one R package for pharmaceutical research. It covers hypothesis tests, regression, survival analysis, dose response, covariate preprocessing and screening, mixed models, diagnostic plots, and reports. Functions expose their inputs and returned results; the documentation records assumptions, evidence, and limitations.

The package is under development and is **not on CRAN**. Its methods and sample data are intended for demonstration and research. They have not been validated for clinical decisions or regulatory compliance.

## What is included

| Workflow | Starting point |
| --- | --- |
| Comparisons, categorical outcomes, and study designs | [Method guide](docs/methods.md) |
| Survival, correlated outcomes, and dose response | [Methods and evidence inventory](docs/method-inventory.md) |
| Imputation, scaling, covariate screening, and mixed-model diagnostics | [Covariate workflow guide](docs/covariate-migration.md) |
| Model tables, rendered reports, and example apps | [Table exports](docs/report-exports.md) and [covariate reports/apps](docs/covariate-migration.md#dependencies-and-installed-resources) |
| Reproducible demonstrations | [Seven illustrative datasets](docs/simulated-data.md) and [six vignettes](docs/covariate-migration.md#worked-vignettes-and-evidence) |

The package has **101 namespace exports**. Optional integrations report missing backends when called; install the dependencies needed for your workflow using the [installation guide](docs/installation.md).

## Install

You need R. From an R session, install from this public GitHub repository:

```r
install.packages("remotes")
remotes::install_github("DiogoRibeiro7/PharmaStatsR")
```

To install the worked vignettes as well, use `remotes::install_github("DiogoRibeiro7/PharmaStatsR", build_vignettes = TRUE)` with `knitr`, `rmarkdown`, and Pandoc installed. For local development, use `devtools::load_all()` from the repository root. See [DESCRIPTION](DESCRIPTION) and the [installation guide](https://diogoribeiro7.github.io/PharmaStatsR/installation/) for required and optional dependencies.

## Migration from PharmaTestSuite

The repository and R package were previously named `PharmaTestSuite`. Reinstall from the URL above and replace `library(PharmaTestSuite)` with `library(PharmaStatsR)` and `citation("PharmaTestSuite")` with `citation("PharmaStatsR")` in existing scripts. Exported `pharma_*` function names have not changed.

## Covariate workflows from pharmoCovR

PharmaStatsR includes all 18 functions formerly provided by pharmoCovR, together with its regression tests, dataset, five vignettes, report template, and Shiny app. The standalone repository was deleted after [the consolidation merged](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/195). Install and use PharmaStatsR for these workflows; it has no runtime dependency on pharmoCovR. Source attribution and the MIT notice are retained in [the imported-module notice](inst/NOTICE-pharmoCovR).

Existing scripts can replace `library(pharmoCovR)` with `library(PharmaStatsR)` and `pharmoCovR::` with `PharmaStatsR::`, retaining function names and arguments. Load the simulated data with `data("pharmo_example", package = "PharmaStatsR")`. See the [migration and method guide](docs/covariate-migration.md) for examples, dependencies, overlap with existing methods, and limitations.

## Quick start

```r
library(PharmaStatsR)

# The included data are small, illustrative examples.
head(pharma_sample)

result <- pharma_t_test(response ~ treatment, data = pharma_sample)
result$estimate
result$conf.int

fit <- pharma_survival_fit(
  survival::Surv(time, status) ~ treatment,
  data = pharma_survival
)
summary(fit)
```

For worked examples and assumptions, read the [method guide](https://diogoribeiro7.github.io/PharmaStatsR/methods/), [equivalence testing guide](https://diogoribeiro7.github.io/PharmaStatsR/equivalence/), and [workflow vignette](vignettes/pharma_workflow.Rmd).

## Project status and documentation

Version **0.1.63** remains in active development. The [API support policy](docs/api-support-policy.md) classifies all 101 exports: two stable column-check helpers, 86 experimental APIs, 11 example-only exports, and two callable historical names proposed for future deprecation. Statistical methods are experimental or example-only.

The numerical-reference batches through #165 and the covariate consolidation are complete within their stated scopes. The [roadmap](ROADMAP.md), [project status](docs/project-status.md), and [evidence inventory](docs/method-inventory.md) distinguish completed work from remaining method gaps.

The [release evidence](docs/release-candidate.md#reviewed-development-baseline-15-october-2026) records merged commit `971a37a`: all five matrix jobs passed, and the inspected all-Suggests source check reported **0 errors, 0 warnings, and 1 note (New submission)**. Ordinary examples and the separate lengthy-example pass both succeeded. The matrix now verifies source/check artifacts and retains a JSON receipt for review. [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) tracks later receipts and the remaining contact, version/source, and release decisions. Each receipt applies to its named commit; later changes require their own checks.

The documentation source is in [`docs/`](docs/) with [`mkdocs.yml`](mkdocs.yml). GitHub Actions checks the MkDocs build on documentation pull requests and deploys the site to [GitHub Pages](https://diogoribeiro7.github.io/PharmaStatsR/) after relevant changes reach `main`. See the [documentation workflow](.github/workflows/docs.yml) and [local build instructions](https://diogoribeiro7.github.io/PharmaStatsR/development/#documentation-site).

## Develop and test

Run `./setup.sh` after installing R. It installs the test dependencies and executes the unit tests. Set `SKIP_R_INSTALL=1` to use an existing R library; missing required packages then cause a clear failure.

Every pull request to `main` runs two Ubuntu R-release package-check jobs: one with required dependencies and check tools, and one with selected optional backends. Documentation changes also run a strict MkDocs build. A separate [R validation matrix](.github/workflows/R-validation-matrix.yaml) runs weekly, on demand, and for package source or candidate-comment changes: macOS and Windows on R release, Ubuntu on R old release and devel with required dependencies, and Ubuntu on R release with every declared Suggested package, Python SciPy, and full manual validation. Both R workflows use `--as-cran` check flags, but a passing matrix is not the complete release-candidate gate in [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58). Read [the check policy](https://diogoribeiro7.github.io/PharmaStatsR/development/#package-checks) for dependencies, skips, and failure handling.

See [CONTRIBUTING.md](CONTRIBUTING.md) for pull request expectations and [SECURITY.md](SECURITY.md) for private vulnerability reports.

## Scope and citation

The helpers do not establish compliance with ICH or FDA guidance. The [reporting and monitoring scope audit](https://diogoribeiro7.github.io/PharmaStatsR/claims-audit/) explains what the column checks, audit log, SAP template, reporting table, and dashboards actually return. Researchers must verify assumptions, calculations, and the suitability of methods for their own analyses. Do not use the example datasets for clinical decisions or include patient data in issues.

Use `citation("PharmaStatsR")` after installation for citation details. The project is licensed under MIT; see [LICENSE.md](LICENSE.md).
