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
| `p.value` | `(1 + exceedances)/(R + 1)`, counting the upper tail including numerical ties as described below; the smallest possible value is `1/(R + 1)`. |

Set a random seed to reproduce the sampled permutations. The fitting data are selected once, using the model's `subset` and missing-data handling, and then held fixed. Formula transformations are evaluated before shuffling. `R` must be a positive whole number; weights and offsets are unsupported.

### Numerical ties

QR refits can give slightly different floating-point values to mathematically equal F statistics. Comparing only `perm >= statistic` can then undercount the upper tail. For a finite observed F value, the comparison is

```r
tolerance <- 100 * .Machine$double.eps * abs(out$statistic)
exceedances <- sum(out$perm >= out$statistic - tolerance)
(1 + exceedances) / (length(out$perm) + 1)
```

The tolerance is relative: zero observed F has zero tolerance. An infinite observed F is compared directly, without computing `Inf - Inf`. **The returned statistics are not rounded or replaced**; only the upper-tail comparison changes. [SciPy's permutation-test documentation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.permutation_test.html) describes the same numerical-tie problem and a relative tolerance of 100 machine epsilons. This convention is not a cure for an ill-conditioned model or arbitrary scaling that destroys numerical information. Inspect the returned distribution when precision is consequential.

Earlier raw comparisons can give smaller p-values for mathematically tied permutations. **Recompute those p-values**; no change to the sampled permutations or returned F values is required.

## Independent small-sample reference

The self-contained [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-permutation-f-reference.R) use five synthetic observations, an intercept, and two orthogonal numeric predictors. Expected values come from projection arithmetic, not another `lm()`, `lm.fit()`, or ANOVA call.

| Case | first | second | response |
| --- | --- | --- | --- |
| case-1 | -2 | 2 | 0 |
| case-2 | -1 | -1 | 1 |
| case-3 | 0 | -2 | 4 |
| case-4 | 1 | -1 | 2 |
| case-5 | 2 | 2 | 7 |

For the design matrix X, `X'X = diag(5, 10, 14)` and `X'y = (14, 15, 3)'`. Therefore the coefficients are `(14/5, 3/2, 3/14)`, the corrected total sum of squares is `154/5`, the regression sum of squares is `162/7`, and the residual sum of squares is `268/35`. The numerator degrees of freedom are `3 - 1 = 2`; the denominator degrees of freedom are `5 - 3 = 2`.

The observed global statistic is

\[
F_{\mathrm{obs}}=\frac{(162/7)/2}{(268/35)/2}=\frac{405}{134}.
\]

The first sequential term instead gives `(45/2)/(134/35) = 1575/268`. The global test is not that first-term test. Both predictors must contribute to the reference.

### Complete permutation support

For a permutation z of `(0, 1, 4, 2, 7)`, set

\[
a=(-2,-1,0,1,2)z,\qquad b=(2,-1,-2,-1,2)z,\qquad
k=\frac{7a^2+5b^2}{4}.
\]

Every k in this fixture is an integer. The total sum of squares is unchanged and the projected sum of squares is `a^2/10 + b^2/14`, so

\[
F(z)=\frac{k}{539-k}.
\]

All 120 labelled permutations are equally weighted. They give the following 37 distinct scores; each row's multiplicity is its frequency among the 120 permutations. Every denominator is positive. No infinite-statistic convention is needed for this fixture.

| k | Multiplicity | k | Multiplicity | k | Multiplicity |
| --- | --- | --- | --- | --- | --- |
| 3 | 4 | 220 | 2 | 405 | 6 |
| 27 | 10 | 223 | 2 | 433 | 4 |
| 33 | 2 | 243 | 12 | 447 | 2 |
| 55 | 2 | 255 | 2 | 468 | 2 |
| 73 | 2 | 283 | 2 | 493 | 2 |
| 75 | 2 | 297 | 8 | 495 | 2 |
| 103 | 2 | 300 | 2 | 507 | 2 |
| 145 | 2 | 307 | 4 | 517 | 2 |
| 157 | 2 | 313 | 2 | 523 | 2 |
| 187 | 8 | 355 | 2 | 528 | 2 |
| 192 | 2 | 363 | 2 | 537 | 4 |
| 195 | 2 | 367 | 4 | — | — |
| 213 | 4 | 388 | 2 | — | — |

The observed score is 405. Exactly 24 permutations are strictly above it and six are tied. The fully enumerated upper-tail probability is **30/120 = 1/4**, not the strict-tail value 24/120. A separate NumPy QR calculation counted only 27 values with a raw floating-point comparison on this fixture; the numerical-tie comparison recovered 30. That numerical reproduction is platform-specific evidence of the comparison problem, not a claim that every R build loses the same three ties.

A base-R reproduction of the exact reference is:

```r
orders <- function(indices) {
  if (length(indices) == 1L) return(matrix(indices, nrow = 1L))
  do.call(rbind, lapply(seq_along(indices), function(i) {
    cbind(indices[i], orders(indices[-i]))
  }))
}
y <- c(0, 1, 4, 2, 7)
k <- apply(orders(seq_along(y)), 1L, function(i) {
  z <- y[i]
  a <- sum(c(-2, -1, 0, 1, 2) * z)
  b <- sum(c(2, -1, -2, -1, 2) * z)
  (7 * a^2 + 5 * b^2) / 4
})
table(k)
stopifnot(sum(k > 405) == 24, sum(k == 405) == 6)
mean(k >= 405) # 1/4; these are exact integer comparisons.
```

### Sampled results, rows, and tolerances

The public helper still samples random permutations; it does **not** switch to exhaustive enumeration when `R >= 120`. Individual draws may repeat. For seeds 7 and 145 and `R = 1, 31, 241`, the tests reproduce only the permutation indices and evaluate each F with the independent score expression. They then check `(1 + sum(k >= 405))/(R + 1)` using exact integer comparisons. No requirement that a random sample approximate 1/4 is used. The fully enumerated probability and the sampled Monte Carlo p-value are different quantities; the [Monte Carlo correction](https://arxiv.org/abs/1603.05766) includes the observed arrangement through the added one.

Every one of the 120 arrangements is also supplied to the production function as an observed response, checking its global F against the independent value. Tests cover returned names, draw count and order, the one-permutation boundary, and post-call random-number state. Test-only seeding restores the previous `.Random.seed` or its absence on normal and error exits; production calls continue to advance the caller's stream.

Positive and negative affine response transformations, including a transformation in the formula, must retain the same F draws and integer-reference tail counts. Two selected incomplete rows and two complete subset exclusions are interleaved with the five reference cases. `na.omit` and `na.exclude` must permute only the same five complete selected observations, verified through both numerical results and the post-call RNG state; `na.fail` must reject the selected incomplete rows before drawing permutations.

F comparisons use a `testthat::expect_equal()` tolerance of `1e-12`. Integer support counts, sampled p-values and RNG state use exact comparisons. This test tolerance is separate from the production upper-tail tolerance. Existing response, weight, offset, replication-count and design guards remain; their backend comparisons use the documented numerical-tie convention for p-values.

This reference covers the complete, full-rank, intercept-containing design and the stated row-selection variants. It does not independently validate no-intercept or rank-deficient models, nuisance-adjusted partial tests, restricted randomization, cluster or time-series exchangeability, or frequentist calibration across data-generating scenarios. It adds no exact-permutation API and no dependency. Statistical support remains experimental.

## Validity and migration

Raw-response permutation requires the observations to be **exchangeable under the global null**. Correlated participants, repeated measures, time ordering, unequal error distributions, or outcome-dependent missingness can violate that requirement. Permutation removes the need for a normal-error reference distribution, but it does not solve these design problems.

The earlier implementation took the **first row of R's sequential ANOVA table**. With several terms, that row represents only the first term and can differ markedly from the whole-model F statistic. R [documents single-model ANOVA tables as sequential](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/anova.lm.html); [permutation inference for more complex models](https://pmc.ncbi.nlm.nih.gov/articles/PMC4010955/) requires schemes suited to the null and dependence structure. **Recompute earlier results** and review whether response exchangeability held. The former crossover-data example was unsuitable for unrestricted response permutations.

See [limitations and validation](limitations.md) for project-wide constraints.

## R help

Full arguments and return values: [`pharma_perm_f_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_perm_f_test.Rd). In an installed package, run `help("pharma_perm_f_test", package = "PharmaStatsR")`.
