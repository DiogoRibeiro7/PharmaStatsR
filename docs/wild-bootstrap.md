# Wild bootstrap coefficient draws

`pharma_wild_bootstrap()` returns coefficient draws from an ordinary least-squares fit. The model matrix stays fixed. For each draw, the function independently changes the sign of each fitted residual and refits the response, with any formula offset retained:

\[
y_i^*=\widehat y_i+\widehat e_i v_i,\qquad
P(v_i=-1)=P(v_i=1)=\tfrac12.
\]

The output has one row per draw and named columns matching `coef(lm(...))`. Set a seed to reproduce the signs.

```r
library(PharmaStatsR)

set.seed(42)
draws <- pharma_wild_bootstrap(
  response ~ treatment, data = pharma_sample, R = 500
)
head(draws)
```

The response must be a finite numeric vector; the formula must be two-sided and all referenced variables must be in `data`. Transformed terms, factors, and formula offsets use the model frame and matrix from the original fit. Missing values in any **model variable** cause an error, while missing values in unrelated columns do not. The design must have full column rank and at least one residual degree of freedom. `R` must be a positive whole number.

## Independent finite-support reference

The [numerical reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-wild-bootstrap-reference.R) use four synthetic observations with `x = c(-1, 0, 1, 2)` and `y = c(0, 0, 6, 8)`. For the unweighted model `y ~ x`, the normal equations give

\[
X^\top X=\begin{pmatrix}4&2\\2&6\end{pmatrix},\qquad
X^\top y=\begin{pmatrix}14\\22\end{pmatrix},\qquad
(X^\top X)^{-1}=\frac1{20}\begin{pmatrix}6&-2\\-2&4\end{pmatrix}.
\]

Thus \(\widehat\beta=(2,3)^\top\), the fitted response is \((-1,2,5,8)^\top\), and the raw residual is \(e=(1,-2,1,0)^\top\). The design has rank two and two residual degrees of freedom. With independent signs \(s_i\in\{-1,1\}\), the conditional coefficient draw has the exact expression

\[
\beta^*=\widehat\beta+A s,\qquad
A=(X^\top X)^{-1}X^\top\operatorname{diag}(e)
=\begin{pmatrix}
2/5&-3/5&1/5&0\\
-3/10&1/5&1/10&0
\end{pmatrix}.
\]

The oracle evaluates these fixed rational coefficients. It does not obtain expected values from `lm()`, `lm.fit()`, `coef()`, `fitted()`, or `residuals()`.

### Complete support and exact moments

Each of the 16 sign vectors has probability `1/16`. Since the fourth residual is zero, either value of `s4` gives the same coefficients for a given first-three-sign combination:

| s1 | s2 | s3 | Intercept draw | Slope draw |
| --- | --- | --- | --- | --- |
| -1 | -1 | -1 | 2 | 3 |
| 1 | -1 | -1 | 14/5 | 12/5 |
| -1 | 1 | -1 | 4/5 | 17/5 |
| 1 | 1 | -1 | 8/5 | 14/5 |
| -1 | -1 | 1 | 12/5 | 16/5 |
| 1 | -1 | 1 | 16/5 | 13/5 |
| -1 | 1 | 1 | 6/5 | 18/5 |
| 1 | 1 | 1 | 2 | 3 |

There are seven distinct coefficient pairs, not 16 equally likely distinct pairs. The center `(2, 3)` has probability `1/4`; each of the other six pairs has probability `1/8`. All sign patterns, including repeated coefficient values, enter the moment calculation:

\[
\mathbb E_s[\beta^*]=(2,3)^\top,\qquad
\operatorname{Cov}_s(\beta^*)=AA^\top
=\begin{pmatrix}14/25&-11/50\\-11/50&7/50\end{pmatrix}.
\]

This is the full conditional distribution, so the enumerated covariance divides by **16**, not the sample-covariance denominator 15. A standalone base-R calculation reproduces the complete reference without fitting a model:

```r
signs <- as.matrix(expand.grid(
  s1 = c(-1, 1), s2 = c(-1, 1), s3 = c(-1, 1), s4 = c(-1, 1),
  KEEP.OUT.ATTRS = FALSE
))
A <- rbind(c(2 / 5, -3 / 5, 1 / 5, 0), c(-3 / 10, 1 / 5, 1 / 10, 0))
draws <- sweep(signs %*% t(A), 2, c(2, 3), "+")
colnames(draws) <- c("(Intercept)", "x")
colMeans(draws)
centered <- sweep(draws, 2, c(2, 3), "-")
crossprod(centered) / nrow(draws)
```

The covariance uses **unadjusted raw residuals**. Its general expression is \((X^\top X)^{-1}X^\top\operatorname{diag}(e_i^2)X(X^\top X)^{-1}\), with no leverage or degrees-of-freedom correction. It is not an HC2/HC3 leverage-corrected covariance, a coverage guarantee, or an interval returned by this helper.

### Seeded draws, ordering, and offsets

The tests replay signs under seeds 11 and 144 and compare every returned row against the independent expression for `R = 1` and `R = 17`. They require a numeric matrix, exact coefficient names, no row names, and the same first draw for one-draw and longer calls. The post-call RNG state must match one four-sign sample per replicate, including the zero-residual row. Expected and actual draws use the same ambient RNG configuration; the tests do not hard-code a sequence across R sampling algorithms. A test-only helper restores the caller's prior `.Random.seed` binding, or its absence, on normal and error exits. This isolation belongs to the tests: the production helper intentionally advances the caller's RNG stream. R documents [seed-state preservation](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html) and [discrete sampling](https://stat.ethz.ch/R-manual/R-devel/library/base/html/sample.html).

A second fixture adds `known = c(1, 0, 2, -1)` to the response and fits `y ~ I(2 * x) + offset(known)`. Its adjusted response and raw residuals are unchanged. The expected intercept remains the table's intercept, and the transformed-predictor coefficient is exactly half its slope. The expected columns are `(Intercept)` and `I(2 * x)`; the offset has no fitted coefficient.

For this transformed design \(Z\), \((Z^\top Z)^{-1}Z^\top\mathrm{known}=(7/10,-1/5)^\top\). Omitting the offset in a refit after a correct initial fit shifts every draw by this nonzero vector; subtracting it twice shifts by the negative vector. The reference therefore distinguishes retaining the offset once from either error. R's [`lm.fit()` documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/lmfit.html) describes its offset argument.

### Tolerances and evidence limits

Numerical assertions use tolerance `1e-12`; dimensions, names, replicate RNG state, and seed restoration use exact comparisons. Exact SymPy 1.14.0 arithmetic checked the 16 patterns, mean, covariance, and offset projection. A separate NumPy 2.3.5 QR calculation agreed with the untransformed coefficient targets to maximum absolute difference below `9e-16`. These independent calculations do not replace executing the R tests in CI.

The finite-support moments are enumerated, not estimated from random draws. No probabilistic pass/fail threshold, new dependency, or production-code change is introduced. The existing [input and algorithm tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-wild-bootstrap.R) remain in place, including missing model data, rank deficiency, and invalid replicate counts. This fixture does not validate frequentist interval coverage, dependent-data resampling, leverage-adjusted residuals, automatic intervals, arbitrary formula transformations, or clinical suitability. The API remains experimental.

## Interpretation

These are draws of the **unstudentized coefficients**, using raw residuals and observation-level Rademacher signs. The helper does not return confidence intervals or p-values, impose a null hypothesis, rescale residuals for leverage, or account for dependence between observations. Its sign draws assume independent observational units; use an appropriate cluster-aware design for clustered or repeated measurements. Interval coverage and test calibration depend on the model and chosen bootstrap procedure. See [limitations and validation](limitations.md).

R documents how [`lm()` builds model frames and applies offsets](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/lm.html); [Davidson and Flachaire (2008)](https://russell-davidson.research.mcgill.ca/articles/wild8-euro.pdf) discuss wild bootstrap versions and inference under heteroskedasticity.

## R help

Full arguments and return values: [`pharma_wild_bootstrap()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_wild_bootstrap.Rd). In an installed package, run `help("pharma_wild_bootstrap", package = "PharmaStatsR")`.
