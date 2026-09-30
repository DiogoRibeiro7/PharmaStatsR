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

For a direct reference with the same imputed object and linear model:

```r
reference <- mice::pool(with(imp, lm(response ~ treatment)))
summary(reference)
```

The CI tests compare the pooled `lm` and Gaussian `glm` summaries with direct
[`with()`](https://amices.org/mice/reference/with.mids.html) and
[`mice::pool()`](https://amices.org/mice/reference/pool.html) results on the same
imputed data. This verifies
the wrapper's delegation; it does not validate an imputation strategy. Review
the imputation model, number of imputations, missing-data assumptions,
convergence, analysis population, and pooling diagnostics for the study.

Despite its name, `pharma_sensitivity_analysis()` fits one analysis model to
the given imputations. It does not vary missingness assumptions or perform a
missing-not-at-random (MNAR) scenario analysis. Define and compare such
scenarios separately in the analysis plan.
