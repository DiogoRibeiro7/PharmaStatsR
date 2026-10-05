# PharmaStatsR

[![R-CMD-check](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml)
[![Documentation](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/docs.yml/badge.svg)](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/docs.yml)

[Documentation site](https://diogoribeiro7.github.io/PharmaStatsR/) · [Roadmap](ROADMAP.md) · [Evidence inventory](docs/method-inventory.md) · [Contributing](CONTRIBUTING.md)

PharmaStatsR is an R package with statistical wrappers and illustrative example data for pharmaceutical research. It covers hypothesis tests, regression, survival analysis, dose response, and other research workflows. Some methods require optional R packages; the corresponding functions report when a backend is missing.

The package is under development and is **not on CRAN**. Its methods and sample data are intended for demonstration and research. They have not been validated for clinical decisions or regulatory compliance.

## Install

You need R. From an R session, install from this public GitHub repository:

```r
install.packages("remotes")
remotes::install_github("DiogoRibeiro7/PharmaStatsR")
```

An alternative for local development is `devtools::load_all()` from the repository root. Optional modelling backends can be installed as needed; see `DESCRIPTION` for the list and the [installation guide](https://diogoribeiro7.github.io/PharmaStatsR/installation/).

## Migration from PharmaTestSuite

The repository and R package were previously named `PharmaTestSuite`. Reinstall from the URL above and replace `library(PharmaTestSuite)` with `library(PharmaStatsR)` and `citation("PharmaTestSuite")` with `citation("PharmaStatsR")` in existing scripts. Exported `pharma_*` function names have not changed.

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

The [roadmap](ROADMAP.md) tracks progress by issue and orders the remaining reviews. The P0 and P1 scope reviews, including [documentation reconciliation](docs/documentation-reconciliation.md), are closed within their stated scope. The [method-evidence batch record](docs/evidence-batches.md) reconciles the completed #129–#131 and #136–#138 reference batches, links their inspected final-PR checks, and defines the diagnostics/resampling batch (#143–#145). Its first implementation adds [independent unweighted linear-model diagnostics](docs/model-diagnostics.md); wild-bootstrap and permutation references remain queued. The [API support policy](docs/api-support-policy.md) classifies all 72 exports: two narrow stable column-check helpers, 58 experimental APIs, ten example-only exports, and two callable historical names proposed for future deprecation. All statistical methods are experimental. The [release candidate checklist](docs/release-candidate.md) and [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) record the latest reviewed merged-commit source check; actual receipt at the designated maintainer address, the final version, candidate-comment review, and a tag decision remain. Closed issues cover their stated scope, not a package-wide clinical validation.

The documentation source is in [`docs/`](docs/) with [`mkdocs.yml`](mkdocs.yml). GitHub Actions checks the MkDocs build on documentation pull requests and deploys the site to [GitHub Pages](https://diogoribeiro7.github.io/PharmaStatsR/) after relevant changes reach `main`. See the [documentation workflow](.github/workflows/docs.yml) and [local build instructions](https://diogoribeiro7.github.io/PharmaStatsR/development/#documentation-site).

## Develop and test

Run `./setup.sh` after installing R. It installs the test dependencies and executes the unit tests. Set `SKIP_R_INSTALL=1` to use an existing R library; missing required packages then cause a clear failure.

Every pull request to `main` runs two Ubuntu R-release package-check jobs: one with required dependencies and check tools, and one with selected optional backends. Documentation changes also run a strict MkDocs build. A separate [R validation matrix](.github/workflows/R-validation-matrix.yaml) runs weekly, on demand, and for package source or candidate-comment changes: macOS and Windows on R release, Ubuntu on R old release and devel with required dependencies, and Ubuntu on R release with every declared Suggested package, Python SciPy, and full manual validation. Both R workflows use `--as-cran` check flags, but a passing matrix is not the complete release-candidate gate in [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58). Read [the check policy](https://diogoribeiro7.github.io/PharmaStatsR/development/#package-checks) for dependencies, skips, and failure handling.

See [CONTRIBUTING.md](CONTRIBUTING.md) for pull request expectations and [SECURITY.md](SECURITY.md) for private vulnerability reports.

## Scope and citation

The helpers do not establish compliance with ICH or FDA guidance. The [reporting and monitoring scope audit](https://diogoribeiro7.github.io/PharmaStatsR/claims-audit/) explains what the column checks, audit log, SAP template, reporting table, and dashboards actually return. Researchers must verify assumptions, calculations, and the suitability of methods for their own analyses. Do not use the example datasets for clinical decisions or include patient data in issues.

Use `citation("PharmaStatsR")` after installation for citation details. The project is licensed under MIT; see [LICENSE.md](LICENSE.md).
