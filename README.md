# PharmaTestSuite

PharmaTestSuite provides statistical test utilities tailored for the pharmaceutical industry. The package aims to simplify the design and execution of common analysis workflows.

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
pharma_t_test(rnorm(10), rnorm(10))
pharma_chisq_test(matrix(c(10,5,6,9), nrow=2))
```

See `ROADMAP.md` for planned features.

## Contact

For questions or feedback, please contact Diogo Ribeiro (<diogo.debastos.ribeiro@gmail.com>).
