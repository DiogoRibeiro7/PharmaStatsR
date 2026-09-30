# Installation

## Requirements

Install a recent version of R. The core package imports `survival`, `stats`, `utils`, `nlme`, and `broom`; R resolves required packages during installation.

PharmaStatsR is not on CRAN. Install it from its **public** GitHub repository:

```r
install.packages("remotes")
remotes::install_github("DiogoRibeiro7/PharmaStatsR")
library(PharmaStatsR)
packageVersion("PharmaStatsR")
```

GitHub authentication is not required to read this public repository. Rate limits may still apply to repeated unauthenticated requests.

Some functions use optional backends. Install only those needed for your analysis; for example:

```r
install.packages(c("geepack", "metafor", "openssl"))
```

To launch either bundled example dashboard, install `rmarkdown`, `flexdashboard`,
and `shiny`:

```r
install.packages(c("rmarkdown", "flexdashboard", "shiny"))
pharma_dashboard()
```

`pharma_dashboard(launch = FALSE)` and
`pharma_interim_dashboard(launch = FALSE)` return the bundled R Markdown paths
without these optional packages.

See the [method guide](methods.md) for examples of optional dependencies. The package's complete dependency metadata is in [DESCRIPTION](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/DESCRIPTION).

## Migrating from PharmaTestSuite

The repository and R package were renamed from `PharmaTestSuite` to `PharmaStatsR`. Reinstall from the URL above, then update existing scripts:

```r
library(PharmaStatsR)
citation("PharmaStatsR")
```

Exported `pharma_*` function names remain the same. Search project files for old `library(PharmaTestSuite)`, `citation("PharmaTestSuite")`, and old repository URLs. The old installed package is separate and can be removed when no longer needed.

## Local development

From a cloned repository with R installed, use `devtools::load_all()` for iteration or `./setup.sh` to install test dependencies and run the tests. See [Development](development.md).
