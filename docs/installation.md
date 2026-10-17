# Installation

## Requirements

Install a recent version of R. The core package imports `survival`, `stats`,
`utils`, `nlme`, `broom`, `gsDesign`, `parallel`, `glmnet`, `tidyr`, `ggplot2`,
and `tidyselect`; R resolves required packages during installation. Covariate
preprocessing, screening, and linear mixed-model diagnostics are included in
this installation.

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

For the Python t-test integration, install `reticulate` and SciPy in the Python
environment it selects. See the [SciPy bridge guide](scipy-bridge.md) for an
interpreter check and example.

Excel and Word table export use separate optional R packages. The
[report export guide](report-exports.md) lists the packages for each format.

See the [method guide](methods.md) for examples of optional dependencies. The package's complete dependency metadata is in [DESCRIPTION](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/DESCRIPTION).

## Covariate reports, app, and nonlinear example

| Feature | Additional requirements |
| --- | --- |
| `run_diagnostics_app()` | `shiny` >= 1.6.0; current release recommended for keyboard tab navigation |
| `generate_report(..., output_format = "html_document")` | `rmarkdown`, `knitr`, and Pandoc |
| `generate_report(..., output_format = "pdf_document")` | The HTML-report requirements plus LaTeX |
| Mixed-model coefficient tidying in reports | `broom.mixed` is optional; the report retains a native `nlme` summary fallback. |
| `fit_nlmixr_model()` | `nlmixr2est`; its worked example also uses `nlmixr2data`. This is a fixed model example, not covariate-aware nonlinear fitting. |

The [covariate guide](covariate-migration.md) documents the installed resources,
entry points, and method limits. These helpers are distinct from the older
dashboard and table-export APIs.

## Worked vignettes

The repository contains six vignettes. GitHub installation does not build them
by default. To make them available through `vignette()`:

```r
install.packages(c("knitr", "rmarkdown"))
# Pandoc must also be available; rmarkdown::pandoc_available() checks this.
remotes::install_github("DiogoRibeiro7/PharmaStatsR", build_vignettes = TRUE)
vignette(package = "PharmaStatsR")
vignette("covariate-quickstart", package = "PharmaStatsR")
```

The [quick start](quickstart.md) also provides examples without a vignette build.

## Migrating from pharmoCovR

The standalone pharmoCovR repository was deleted after its complete package
functionality was merged into PharmaStatsR. Install from the PharmaStatsR URL
above, replace `library(pharmoCovR)` with `library(PharmaStatsR)`, and replace
`pharmoCovR::` prefixes with `PharmaStatsR::`. Function names and arguments are
preserved. Load the additional dataset explicitly:

```r
data("pharmo_example", package = "PharmaStatsR")
```

The [migration guide](covariate-migration.md) records provenance and the original
MIT notice. No separate pharmoCovR installation is needed.

## Migrating from PharmaTestSuite

The repository and R package were renamed from `PharmaTestSuite` to `PharmaStatsR`. Reinstall from the URL above, then update existing scripts:

```r
library(PharmaStatsR)
citation("PharmaStatsR")
```

Exported `pharma_*` function names remain the same. Search project files for old `library(PharmaTestSuite)`, `citation("PharmaTestSuite")`, and old repository URLs. The old installed package is separate and can be removed when no longer needed.

## Local development

From a cloned repository with R installed, use `devtools::load_all()` for iteration or `./setup.sh` to install test dependencies and run the tests. See [Development](development.md).
