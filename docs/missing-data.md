# Multiple imputation and pooling

`pharma_mice_impute()` calls [`mice::mice()`](https://amices.org/mice/reference/mice.html)
and returns a `mids` object.
`pharma_sensitivity_analysis()` fits a linear model to each completed dataset,
or a generalized linear model when `family` is supplied, and pools the model
estimates with `mice::pool()`. Both functions require the optional `mice`
package:

```r
install.packages("mice")

dat <- pharma_sample
dat$response[1] <- NA_real_
imp <- pharma_mice_impute(dat, m = 2, maxit = 1, seed = 41)
pooled <- pharma_sensitivity_analysis(imp, response ~ treatment)
summary(pooled)
```

The output is a `mipo` pooled model. Supplying `family = binomial()` selects
`stats::glm()` in place of `stats::lm()`; the formula and extra model arguments
are applied to every completed dataset. The imputation wrapper suppresses
`mice` progress output. If `mice` is unavailable, each function names it and
shows `install.packages('mice')` in the error. There is no substitute backend.

## Fixed pooling reference

A deterministic example has three untreated responses (0, 2, 4), two
observed treated responses (4, 6), and one missing treated response. Set
the missing value to 5, 7, and 9 in three completed datasets, respectively.
For `response ~ treatment`, the coefficient is the treated mean minus the
untreated mean. The [reference test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-imputation-pooling-reference.R)
constructs a `mids` object from these fixed completed datasets with
`mice::as.mids()`; it does not sample imputations.

| Completed missing value | Treatment coefficient | Residual sum of squares | Within variance of coefficient |
| ---: | ---: | ---: | ---: |
| 5 | 3 | 10 | 5/3 |
| 7 | 11/3 | 38/3 | 19/9 |
| 9 | 13/3 | 62/3 | 31/9 |

Each fitted model has four residual degrees of freedom. In this balanced
two-group design, the coefficient variance is the residual mean square
times `1/3 + 1/3 = 2/3`. Rubin's rules give pooled coefficient
`Qbar = 11/3`, mean within variance `Ubar = 65/27`, and sample variance
of the three coefficients `B = 4/9`. Total variance is
`T = Ubar + (1 + 1/3) B = 3`, yielding pooled standard error
`sqrt(3)`. The test checks these components in the wrapper's `mipo`
result directly; the values do not come from a second call to
`mice::pool()`. The wrapper rejects input that is not a `mids` object.

This fixed construction checks the model fitting and pooling path for one
linear coefficient. It does not assess an imputation model's convergence,
coverage, or assumptions, and a single imputation strategy is not an MNAR
sensitivity analysis.

For a direct reference with the same imputed object and linear model:

```r
reference <- mice::pool(with(imp, lm(response ~ treatment)))
summary(reference)
```

The CI tests compare the pooled `lm` and Gaussian `glm` summaries with direct
[`with()`](https://amices.org/mice/reference/with.mids.html) and
[`mice::pool()`](https://amices.org/mice/reference/pool.html) results on the same
imputed data. This verifies the wrapper's delegation on generated imputations; the fixed
reference above separately checks one pooled coefficient and its variance. Review
the imputation model, number of imputations, missing-data assumptions,
convergence, analysis population, and pooling diagnostics for the study.

Despite its name, `pharma_sensitivity_analysis()` fits one analysis model to
the given imputations. It does not vary missingness assumptions or perform a
missing-not-at-random (MNAR) scenario analysis. Define and compare such
scenarios separately in the analysis plan.

## R help

Full arguments and return values:

- [`pharma_mice_impute()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_mice_impute.Rd)
- [`pharma_sensitivity_analysis()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_sensitivity_analysis.Rd)

In an installed package, run `help(package = "PharmaStatsR")` to open the corresponding topics.
