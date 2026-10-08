# Woolf odds-ratio homogeneity test

`pharma_woolf_test()` tests heterogeneity of 2×2 stratum-specific odds ratios
using inverse-variance weighted log odds ratios.

For stratum \(s\),

\[
\ell_s = \log\left(\frac{a_s d_s}{b_s c_s}\right),
\qquad
V_s = \frac1{a_s}+\frac1{b_s}+\frac1{c_s}+\frac1{d_s},
\qquad
w_s=V_s^{-1}.
\]

The pooled log odds ratio is

\[
\bar\ell = \frac{\sum_s w_s\ell_s}{\sum_s w_s},
\]

and Woolf's homogeneity statistic is

\[
Q_W = \sum_s w_s(\ell_s-\bar\ell)^2,
\]

with \(K-1\) degrees of freedom.

## Independent reference

For three strata

```r
x <- array(0, dim = c(2, 2, 3))
x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
x[, , 2] <- matrix(c(6, 4, 3, 7), 2, byrow = TRUE)
x[, , 3] <- matrix(c(9, 1, 4, 6), 2, byrow = TRUE)

pharma_woolf_test(x)
```

the independent targets are:

- log odds ratios ≈ \((2.7725887222, 1.2527629685, 2.6026896854)\);
- variances \((1.25, 25/28, 55/36)\);
- weights \((0.8, 1.12, 36/55)\);
- pooled log odds ratio ≈ \(2.0682269161\);
- \(Q_W \approx 1.3286508718\);
- 2 degrees of freedom.

The tests also verify stratum-order invariance, a zero-statistic identical-strata
boundary, and rejection of zero-cell tables.

## Interpretation limits

Woolf's test is a large-sample log-odds-ratio test and requires strictly
positive cells. It is less suitable for sparse tables and does not replace the
fixed-margin Breslow-Day/Tarone test when that formulation is preferred.

## R help

Full arguments and return values:
[`pharma_woolf_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_woolf_test.Rd).
