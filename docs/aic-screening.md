# Stepwise AIC covariate screening

`screen_covariates_stepwise()` starts with an intercept-only Gaussian linear
model, then considers adding and removing whole candidate terms using
[`stats::step()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/step.html).
It returns original selected names in the final model's term order. That order
can differ from the input candidate order.

All models use the same rows, complete for the response and every requested
candidate. Unused columns, including subject IDs, do not determine that cohort.
The `id` argument checks that the named column exists; it does not fit subject
effects or account for repeated-measure correlation. The model assumes
independent Gaussian errors with constant variance.

## Criterion and search

For `n` retained observations, regression rank `p` including the intercept, and
residual sum of squares `RSS`, the criterion is

\[
AIC_{step} = n\log(RSS/n) + 2p.
\]

This follows the unknown-scale Gaussian
[`extractAIC()` convention](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/extractAIC.html).
Its additive constant differs from `AIC(lm(...))`, including the variance
parameter's contribution. Differences between models on the shared cohort
are comparable. A factor enters or leaves as a whole term, with the penalty
corresponding to its additional fitted coefficients.

The helper retains the backend's greedy search, comparison tolerances and
handling of aliased terms. It does not enumerate every subset or guarantee a
global minimum. Ties and near ties can depend on input order and rounding.
These scores do not provide a significance test, multiplicity correction, or
valid post-selection confidence intervals.

## Independent forward/backward reference

The columns below are mutually orthogonal before constructing the proxy. Each
has mean zero and squared norm 16.

```r
library(PharmaStatsR)
u <- rep(c(-1, 1), 8)
v <- rep(c(-1, -1, 1, 1), 4)
w <- rep(c(rep(-1, 4), rep(1, 4)), 2)
z <- rep(c(-1, 1), each = 8)
d <- data.frame(
  id = 1:16, y = u + 1.1 * v + 0.2 * z,
  u = u, v = v, proxy = u + v + w
)
screen_covariates_stepwise(d, "y", "id", c("u", "v", "proxy"))
# [1] "v" "u"
```

The null RSS is `16 * (1 + 1.1^2 + 0.2^2) = 36`. The proxy has squared norm 48
and inner product 33.6 with the response, so its RSS is
`36 - 33.6^2 / 48 = 12.48`. Adding `v` leaves half of the `u` component plus
the error, giving `16 * (0.5 + 0.04) = 8.64`. Adding `u` leaves only `0.2*z`,
with RSS 0.64. The proxy can then be removed without changing RSS.

| Accepted step | RSS | Rank | Criterion |
| --- | ---: | ---: | ---: |
| Intercept | 36 | 1 | 14.974883 |
| Add `proxy` | 12.48 | 2 | 0.024618 |
| Add `v` | 8.64 | 3 | -3.858978 |
| Add `u` | 0.64 | 4 | -43.502013 |
| Remove `proxy` | 0.64 | 3 | -45.502013 |

The tests compare the actual accepted path, residual degrees of freedom, RSS
and criterion against this independently derived ledger. They also compare all
eight subset scores from fixed RSS values, without another model-fitting
backend. Additional references cover the whole-factor penalty, complete-case
selection, equivalent coding/scales, literal names, redundant columns and
saturated/non-finite boundaries.

## A local minimum is possible

Change the response and proxy in the same fixture:

```r
d$y <- u + v + 0.2 * z
d$proxy <- u + v + 0.5 * w
screen_covariates_stepwise(d, "y", "id", c("u", "v", "proxy"))
# [1] "proxy"
```

The proxy RSS is `16 * (2.04 - 4/2.25)`. Adding either `u` or `v` reduces RSS to
3.84, but the extra coefficient increases AIC. The search therefore stops at
`proxy`, although the `u + v` model has RSS 0.64 and a lower AIC. This limitation
is an explicit numerical reference, not a promise of exhaustive selection.

## Invalid fitted models and migration

The starting model, each accepted model and the returned model must have
positive residual degrees of freedom and a finite criterion. A violation stops
the call with the original term names; no partial selection is returned.

Earlier versions could return a saturated factor with one level per retained
observation, or proceed with a non-finite starting score. These cases now raise
clear errors. A non-finite criterion can result from exact fits or residual
squares outside floating-point range. Review exact fits and rescale extreme
response units before retrying. Finite near-perfect fits remain allowed and
may still trigger backend warnings.

The checks do not preflight every trial model or require the full candidate
design to have positive residual degrees of freedom. An overcomplete or aliased
scope can still yield a valid accepted path. One residual degree of freedom is
allowed, without establishing small-sample adequacy.

The signature and valid search behavior are unchanged; there are no new exports,
dependencies or version changes. The method remains experimental. See the
[BIC screener](bic-screening.md) for independent univariate comparisons and the
[migration guide](covariate-migration.md) for the wider covariate workflow.
