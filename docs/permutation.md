# Global permutation F-test

`pharma_perm_f_test()` tests whether **all predictors in a linear model jointly** improve fit over an intercept-only model. If the formula omits an intercept, the comparison is with a zero-mean model. It permutes the evaluated numeric response across the rows used in the fit while keeping the design matrix fixed.

```r
library(PharmaStatsR)

independent <- data.frame(
  response = c(1, 2, 2, 4, 2, 3, 5, 7),
  group = rep(c("A", "B"), each = 4),
  dose = rep(1:4, times = 2)
)

set.seed(7)
out <- pharma_perm_f_test(
  response ~ group + dose, data = independent, R = 999
)
out$statistic
out$p.value
```

This example treats the eight rows as independent observations. The function tests `group` and `dose` **together**. It does not test the group effect after adjusting for dose. An individual model term requires a different permutation design that respects the nuisance terms.

## Returned values

| Field | Meaning |
| --- | --- |
| `statistic` | Global observed F statistic for the full model against the null model. |
| `perm` | Global F statistics from `R` random response permutations. |
| `p.value` | \((1+\#\{F_{\mathrm{perm}}\ge F_{\mathrm{obs}}\})/(R+1)\), so the smallest possible value is \(1/(R+1)\). |

Set a random seed to reproduce the sampled permutations. The fitting data are selected once, using the model's `subset` and missing-data handling, and then held fixed. Formula transformations are evaluated before shuffling. `R` must be a positive whole number; weights and offsets are unsupported.

## Validity and migration

Raw-response permutation requires the observations to be **exchangeable under the global null**. Correlated participants, repeated measures, time ordering, unequal error distributions, or outcome-dependent missingness can violate that requirement. Permutation removes the need for a normal-error reference distribution, but it does not solve these design problems.

The earlier implementation took the **first row of R's sequential ANOVA table**. With several terms, that row represents only the first term and can differ markedly from the whole-model F statistic. R [documents single-model ANOVA tables as sequential](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/anova.lm.html); [permutation inference for more complex models](https://pmc.ncbi.nlm.nih.gov/articles/PMC4010955/) requires schemes suited to the null and dependence structure. **Recompute earlier results** and review whether response exchangeability held. The former crossover-data example was unsuitable for unrestricted response permutations.

See [limitations and validation](limitations.md) for project-wide constraints.
