# PharmaTestSuite

[![R-CMD-check](https://github.com/DiogoRibeiro7/PharmaTestSuite/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DiogoRibeiro7/PharmaTestSuite/actions/workflows/R-CMD-check.yaml)

PharmaTestSuite provides statistical test utilities tailored for the pharmaceutical industry. The package aims to simplify the design and execution of common analysis workflows and includes helpers for basic regulatory compliance checks.

## Installation

PharmaTestSuite is not yet available on CRAN. You can install the development version from GitHub:

```r
# install.packages("devtools")
# devtools::install_github("DiogoRibeiro7/PharmaTestSuite")
```

## Example

```r
library(PharmaTestSuite)
pharma_greeting()

# built-in datasets
data(pharma_sample)
data(pharma_crossover)
data(pharma_survival)
data(pharma_repeated)

pharma_t_test(rnorm(10), rnorm(10))
pharma_chisq_test(matrix(c(10,5,6,9), nrow=2))
pharma_anova(response ~ treatment, data = pharma_sample)
pharma_logistic_regression(outcome ~ dose, data = pharma_sample)
pharma_survival_fit(survival::Surv(time, status) ~ treatment, data = pharma_survival)
pharma_parametric_survival(survival::Surv(time, status) ~ treatment,
                          data = pharma_survival,
                          dist = "weibull")
pharma_cox_timevarying(Surv(start, stop, status) ~ treatment,
                       data = pharma_survival)
pharma_competing_risks(Surv(time, status) ~ treatment,
                       data = pharma_survival)
pharma_landmark_analysis(Surv(time, status) ~ treatment,
                         data = pharma_survival,
                         landmark = 12)
pharma_repeated_anova(response ~ condition + Error(subject), data = pharma_repeated)
pharma_lmm(response ~ condition + (1|subject), data = pharma_repeated)
pharma_gee(response ~ condition, id = subject, data = pharma_repeated)
fit <- pharma_bayesian_glm(outcome ~ dose, data = pharma_sample, iter = 500, chains = 2)
pharma_posterior_summary(fit)
if (requireNamespace("bayesplot", quietly = TRUE)) {
  pharma_pp_check(fit)
}
check_ich_columns(pharma_sample)
```
**Note:** All datasets included in PharmaTestSuite are simulated examples only and should not be used to make clinical decisions. The package is intended for demonstration and educational purposes.

See `ROADMAP.md` for planned features.

## Contact

For questions or feedback, please contact Diogo Ribeiro
(<diogo.debastos.ribeiro@gmail.com>),
ESMAD, Instituto Politécnico do Porto.
ORCID: <https://orcid.org/0009-0001-2022-7072>.
