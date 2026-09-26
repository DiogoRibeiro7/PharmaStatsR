# PharmaStatsR

[![R-CMD-check](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml)

PharmaStatsR is an R package with statistical wrappers and simulated example data for pharmaceutical research. It covers hypothesis tests, regression, survival analysis, dose response, and other research workflows. Some methods require optional R packages; the corresponding functions report when a backend is missing.

The package is under development and is **not on CRAN**. Its methods and sample data are intended for demonstration and research. They have not been validated for clinical decisions or regulatory compliance.

## Install

You need R and access to this repository. From an R session with GitHub authentication configured for this private repository:

```r
install.packages("remotes")
remotes::install_github("DiogoRibeiro7/PharmaStatsR")
```

An alternative for local development is `devtools::load_all()` from the repository root. Optional modelling backends can be installed as needed; see `DESCRIPTION` for the list.

## Migration from PharmaTestSuite

The repository and R package were previously named `PharmaTestSuite`. Reinstall from the URL above and replace `library(PharmaTestSuite)` with `library(PharmaStatsR)` and `citation("PharmaTestSuite")` with `citation("PharmaStatsR")` in existing scripts. Exported `pharma_*` function names have not changed.

## Quick start

```r
library(PharmaStatsR)

# The included data are small, simulated examples.
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

For a longer example, read the [workflow vignette](vignettes/pharma_workflow.Rmd). The [roadmap](ROADMAP.md) records future work; items there should not be taken as implemented functionality.

## Develop and test

Run `./setup.sh` after installing R. It installs the test dependencies and executes the unit tests. Set `SKIP_R_INSTALL=1` to use an existing R library; missing required packages then cause a clear failure.

Every pull request to `main` runs an Ubuntu R CMD check with the package's required dependencies and the test and vignette toolchain. Checks for optional statistical backends are exercised when those packages are installed. A full CRAN preparation check, including optional packages and additional platforms, remains work in progress.

See [CONTRIBUTING.md](CONTRIBUTING.md) for pull request expectations and [SECURITY.md](SECURITY.md) for private vulnerability reports.

## Scope and citation

The helpers do not establish compliance with ICH or FDA guidance. Researchers must verify assumptions, calculations, and the suitability of methods for their own analyses. Do not use the simulated datasets for clinical decisions or include patient data in issues.

Use `citation("PharmaStatsR")` after installation for citation details. The project is licensed under MIT; see [LICENSE.md](LICENSE.md).
