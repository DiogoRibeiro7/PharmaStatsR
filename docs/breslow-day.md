# Breslow-Day odds-ratio homogeneity test

`pharma_breslow_day_test()` tests whether 2×2 stratum-specific odds ratios are
compatible with a common odds ratio.

This complements the Cochran-Mantel-Haenszel helper:

- `pharma_cmh_test()` tests a common conditional association and reports a
  Mantel-Haenszel common odds ratio;
- `pharma_breslow_day_test()` tests whether the common-odds-ratio assumption
  is plausible across strata.

## Independent reference

Consider two strata:

```r
x <- array(0, dim = c(2, 2, 2))
x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
x[, , 2] <- matrix(c(2, 8, 8, 2), 2, byrow = TRUE)

pharma_breslow_day_test(x)
```

Both strata have row and column margins `(10, 10)`. The Mantel-Haenszel
common odds ratio is

\[
\hat\theta_{MH}
=
\frac{8\cdot 8/20 + 2\cdot 2/20}
     {2\cdot 2/20 + 8\cdot 8/20}
=1.
\]

Under fixed margins and common odds ratio 1, the fitted upper-left count is 5
in each stratum. The large-sample conditional variance is

\[
V
=
\left(
\frac{1}{5}+\frac{1}{5}+\frac{1}{5}+\frac{1}{5}
\right)^{-1}
=
\frac54.
\]

Therefore

\[
X^2_{BD}
=
\frac{(8-5)^2}{5/4}
+
\frac{(2-5)^2}{5/4}
=
\frac{72}{5}
=
14.4,
\]

with 1 degree of freedom.

The tests also cover stratum-order invariance, a homogeneous zero-statistic
boundary, malformed arrays, invalid counts, empty margins, and undefined common
odds ratios.

## Interpretation limits

A significant Breslow-Day result is evidence against a shared odds ratio across
strata. It does not identify a causal interaction, estimate a parametric
effect-modification model, or explain why strata differ. Sparse or boundary
tables can make the large-sample approximation inappropriate.

## R help

Full arguments and return values:
[`pharma_breslow_day_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_breslow_day_test.Rd).
