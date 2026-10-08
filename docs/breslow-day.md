# Breslow-Day odds-ratio homogeneity test

`pharma_breslow_day_test()` tests whether 2×2 stratum-specific odds ratios are
compatible with a common odds ratio. Set `tarone = TRUE` to apply Tarone's
adjustment for estimating the common odds ratio from the same strata.

This complements the Cochran-Mantel-Haenszel helper:

- `pharma_cmh_test()` tests a common conditional association and reports a
  Mantel-Haenszel common odds ratio;
- `pharma_breslow_day_test()` tests whether the common-odds-ratio assumption
  is plausible across strata.

## Unadjusted independent reference

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

## Tarone adjustment

For fitted counts \(E_s\), observed upper-left counts \(a_s\), and
large-sample variances \(V_s\), the adjustment is

\[
C_T
=
\frac{\left[\sum_s(a_s-E_s)\right]^2}
     {\sum_s V_s},
\qquad
X^2_T = X^2_{BD} - C_T.
\]

A fixed three-stratum reference gives

- common odds ratio \(8/3\);
- unadjusted statistic \(10.9935914671\);
- Tarone correction \(0.1178429868\);
- adjusted statistic \(10.8757484803\);
- 2 degrees of freedom.

Use:

```r
x <- array(0, dim = c(2, 2, 3))
x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
x[, , 2] <- matrix(c(2, 8, 5, 5), 2, byrow = TRUE)
x[, , 3] <- matrix(c(9, 1, 4, 6), 2, byrow = TRUE)

pharma_breslow_day_test(x, tarone = TRUE)
```

The tests verify that `tarone = FALSE` preserves the original statistic,
that the adjusted statistic is no larger than the unadjusted statistic, and
that both forms are invariant to stratum ordering.

## Interpretation limits

A significant Breslow-Day result is evidence against a shared odds ratio across
strata. It does not identify a causal interaction, estimate a parametric
effect-modification model, or explain why strata differ. Tarone's adjustment
accounts for estimating the common odds ratio in the test statistic; it does not
solve sparse-data or fitted-boundary limitations.

## R help

Full arguments and return values:
[`pharma_breslow_day_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_breslow_day_test.Rd).
