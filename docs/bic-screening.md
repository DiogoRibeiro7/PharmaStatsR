# BIC-based covariate screening

`screen_covariates_bayesian()` compares each candidate with an intercept-only
Gaussian linear model. It returns the original candidate names whose BIC-based
approximate Bayes factor meets `min_bf` (default 3), in the supplied order.
Numeric candidates add one slope; categorical candidates are whole terms.

This is univariate screening. Each candidate is fitted separately, without
adjustment for the other candidates. The scores are neither exact Bayes factors
nor posterior inclusion probabilities from a joint Bayesian model. Errors are
assumed independent, Gaussian and of constant variance. Subject IDs do not
model repeated-measure correlation. No multiplicity correction or post-selection
inference is provided.

## Score and analysis population

Every fit uses the same rows that are complete for the response and **all**
requested candidates. Missing values in unused columns do not remove rows.
Adding a candidate with missing observations can therefore change every score.
Unused factor levels are dropped on that shared cohort.

For a null model (0) and one candidate model (1),

\[
\log(\widehat{BF}_{10}) = \frac{BIC_0-BIC_1}{2}
= \frac{n\log(RSS_0/RSS_1)-(p_1-p_0)\log(n)}{2}.
\]

Here `n` is the retained row count, `RSS` is residual sum of squares, and `p`
is regression rank including the intercept. The estimated Gaussian variance
contributes one parameter to both BIC values and cancels in the difference.
A three-level factor ordinarily adds two coefficients and receives a two-parameter
penalty. The implementation uses R's maximum-likelihood Gaussian
[`BIC()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/AIC.html)
and [`logLik.lm()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/logLik.html)
conventions. It compares `log(BF)` with `log(min_bf)` inclusively, avoiding
exponentiation of large scores.

## Reproduce the numerical reference

The following components are mutually orthogonal after centering. Their sums of
squares are 135 for `1.5*x`, 128 for `group_effect`, and 12 for `error`.

```r
library(PharmaStatsR)
x <- rep(c(-3, -1, 1, 3), 3)
error <- rep(c(1, -1, -1, 1), 3)
group_effect <- rep(c(-4, 0, 4), each = 4)
d <- data.frame(
  y = 2 + 1.5 * x + group_effect + error,
  x = x, group = factor(group_effect), weak = error
)

screen_covariates_bayesian(d, "y", c("x", "group", "weak"))
# [1] "x" "group"
screen_covariates_bayesian(d, "y", c("x", "group", "weak"), min_bf = 5)
# [1] "x"
```

The null RSS is `135 + 128 + 12 = 275` on 12 rows. Removing each fitted component
from that sum gives independent reference scores:

| Candidate | Alternative RSS | Additional coefficients | Approximate BF |
| --- | ---: | ---: | ---: |
| `x` | 140 | 1 | 16.582016 |
| `group` | 147 | 2 | 3.571996 |
| `weak` | 263 | 1 | 0.377286 |

For example, the numeric score is
`exp((12 * log(275 / 140) - log(12)) / 2)`.
The reference tests compute these targets without fitting another model or
calling `BIC()`/`logLik()`. They bracket each threshold and cover shared
missing-row selection, row permutations, response and predictor transformations,
factor coding, original names, and finite scores above the representable
Bayes-factor range.

## Invalid comparisons and migration

At least three complete rows and variation in each selected column are required.
Every fitted model must also have positive residual degrees of freedom and a
finite BIC. An invalid candidate stops the whole call with its original name;
the function does not return a partial selection.

A factor with one level per retained observation is saturated. Earlier versions
could select it despite having no residual degrees of freedom. It now raises
an error. A factor with one residual degree of freedom is allowed; this boundary
does not establish that a small sample supports the BIC approximation.

Finite response values can still produce non-finite likelihoods when residual
squares underflow or overflow. Earlier versions could silently omit candidates
or select them on an infinite score. Such comparisons now raise a contextual
error. Review exact fits and rescale extreme response units before retrying.
There is no near-zero residual-variance cutoff: finite near-perfect fits can
still produce very large scores and require scientific review.

The signature, default threshold, return type and valid finite comparisons are
unchanged. No new dependency or export is introduced. The helper remains
experimental; these reference cases cover its documented calculation, not its
suitability for an analysis. See the [migration guide](covariate-migration.md)
and [method inventory](method-inventory.md).
