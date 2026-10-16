<div class="pharma-hero" markdown="1">

# Statistical workflows with clear assumptions

Explore statistical and covariate workflows in one R package, with illustrative data, runnable examples, and explicit limits on interpretation.

[Get started](installation.md){ .md-button .md-button--primary }
[Read the method guide](methods.md){ .md-button }

</div>

<div class="pharma-cards" markdown="1">

<div markdown="1">

### Compare and estimate

Use wrappers for group comparisons, survival models, and other research analyses. [Browse methods](methods.md).

</div>

<div markdown="1">

### Reproduce an example

Start with the included example datasets and inspect the returned estimates and uncertainty. [Try the quick start](quickstart.md).

</div>

<div markdown="1">

### Prepare covariates and inspect a model

Impute missing values, reuse scaling parameters, screen covariates, and produce diagnostics or reports. [Explore the consolidated module](covariate-migration.md).

</div>

<div markdown="1">

### Check the limits

Review assumptions, optional backends, and the actual scope of the reporting and monitoring helpers. [Read the scope audit](claims-audit.md).

</div>

</div>

## About the package

PharmaStatsR is an R package with statistical wrappers, illustrative data, and example workflows for pharmaceutical research. It is under development and **not on CRAN**. Its examples support learning and exploratory research; the package has not been validated for clinical decisions or regulatory submissions.

The [project status](project-status.md) shows which roadmap reviews have closed, which remain open, and what evidence is needed before a release candidate. The [export and evidence inventory](method-inventory.md) records review levels for individual methods.

Version 0.1.63 includes 109 namespace exports, seven illustrative datasets, and
six vignettes. All 18 functions formerly maintained in pharmoCovR now live here;
the standalone repository has been deleted. Follow the [migration guide](covariate-migration.md)
to update existing scripts, or start with the [installation guide](installation.md).

The installed R manual documents function arguments and return values. In R, run `help(package = "PharmaStatsR")` or `?pharma_tost`. See the [source repository](https://github.com/DiogoRibeiro7/PharmaStatsR), [changelog](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/NEWS.md), and [detailed roadmap](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/ROADMAP.md).
