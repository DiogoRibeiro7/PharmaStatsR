# Core inference reference cases

These small fixed fixtures give numerical checks for the six helpers in [roadmap issue #49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49). The expected probabilities and quantiles were evaluated with **SciPy 1.17.0**, independently of the R wrappers. Sums of squares, group means, event proportions, and variance inputs are stated below so the targets can also be checked by hand. Tests use fixed expected numbers rather than comparing each wrapper only with its R backend. They establish the listed calculations on these fixtures, not general clinical validity.

| Helper and test | Fixture, assumption, and independent target |
| --- | --- |
| [`pharma_t_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-core-inference-references.R) | Independent groups `x = (1,2,3,4)` and `y = (2,4,6,8)`. Means 2.5 and 5; sample variances 5/3 and 20/3. Welch SE = 5/√12, df = 75/17, t = −√3; two-sided p = 0.151580504845, 95% interval for mean difference = [−6.364167215486, 1.364167215486]. The lower-tail p = 0.075790252423 and upper one-sided confidence limit = 0.496365257232. The equal-variance option has df = 6 and p = 0.133974596216 on the same observations. |
| [`pharma_tost()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-core-inference-references.R) | Independent groups `x = (2,3,4,5)`, `y = (1,2,3,4)`, difference 1, equal sample variances 5/3. Welch SE = √(5/6), df = 6. With prespecified bounds (−1, 3), one-sided t statistics are ±2.190890230021, maximum one-sided p = 0.035493827160, and 90% interval = [−0.773872788229, 2.773872788229]. Changing the upper bound to 2 raises the maximum p to 0.157666798101. |
| [`pharma_chisq_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-core-inference-references.R) | For a 2×2 independent contingency table with rows `(10,20)` and `(20,10)`, all expected counts are 15. Pearson χ² without continuity correction is 20/3, df = 1, upper-tail p = 0.009823274508. R's default Yates correction gives χ² = 5.4 and p = 0.020136751550. Negative counts error. |
| [`pharma_anova()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-core-inference-references.R) | Independent observations with one categorical factor: groups `(1,2,3)`, `(4,5,6)`, `(7,8,9)`. Group means are 2, 5, 8; between SS = 54, within SS = 6, df = (2,6), MS = (27,1), F = 27, upper-tail p = 0.001. The ordinary F interpretation also assumes an appropriate residual distribution and common within-group variance. Numeric group codes error until explicitly converted to a factor. |
| [`pharma_rate_metrics()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-rate-metrics.R) | Independent binomial groups with 10/100 and 15/110 events. Risk difference = −0.036363636364; Newcombe interval from SciPy Wilson bounds = [−0.124995611001, 0.054351684212]. Unadjusted risk ratio = 0.733333333333; half-count adjusted log interval = [0.356787735921, 1.553490114884]. Existing tests also check a 90% interval, zero events, all events, and invalid counts. These intervals are approximate. |
| [`pharma_sample_reestimate()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-sample-size.R) | Balanced independent normal groups, mean difference 0.5, common per-person variance 1, two-sided α = 0.05, target normal-approximation power 0.8. With `n/arm = 2σ²(z₁₋α/₂ + z_power)²/δ²`, the unrounded target is 62.791037874793 per arm, so the returned balanced total is 126. Tests also check sign symmetry, rounding, input limits, and two other fixed targets. This is a planning calculation, not conditional power. |

The fixed tail values use `scipy.stats.t`, `chi2`, and `f`; the Wilson bounds use `scipy.stats.binomtest(...).proportion_ci(method="wilson")`; and planning quantiles use `scipy.stats.norm.ppf`. Group order, variance choice, and confidence level are explicit because changing any of them changes the numerical target. See [limitations and validation](limitations.md) and the [export inventory](method-inventory.md) for the remaining review work.

## R help

Full arguments and return values:

- [`pharma_t_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_t_test.Rd)
- [`pharma_chisq_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_chisq_test.Rd)

In an installed package, run `help(package = "PharmaStatsR")` to open the corresponding topics.
