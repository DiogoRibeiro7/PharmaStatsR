# Sample size for two independent means

`pharma_sample_reestimate()` calculates an **approximate planning total** for a balanced two-arm comparison of independent normal outcomes. Despite its historical name, the function calculates unconditional normal-approximation power; it does not use accumulated trial data or compute conditional power.

```r
library(PharmaStatsR)

# A mean difference of 0.5, common within-arm variance of 1,
# 80% target power and a two-sided 5% significance level.
pharma_sample_reestimate(
  current_n = 50, effect = 0.5, variance = 1
)
#> [1] 126
```

## Inputs and calculation

| Input | Meaning |
| --- | --- |
| `current_n` | Current or already planned **total**, used as a floor. |
| `effect` | Assumed nonzero difference of arm means in outcome units. Its sign does not change a two-sided calculation. |
| `variance` | Common variance of **individual outcomes within an arm**, in squared outcome units. This is not the standard deviation or the variance of a difference of sample means. |
| `target_power` | Desired approximate power, strictly above 0.5 and below 1. |
| `alpha` | Overall two-sided significance level, strictly between zero and one. |

For \(n\) participants **per arm**, the variance of the difference in sample means is \(2\sigma^2/n\). The function calculates the per-arm planning target

\[
n_{\mathrm{arm}} =
\left\lceil
  \frac{2\sigma^2
  \left(z_{1-\alpha/2}+z_{\mathrm{power}}\right)^2}{\Delta^2}
\right\rceil,
\]

where \(\Delta\) is `effect` and \(\sigma^2\) is `variance`. It then returns

\[
N_{\mathrm{total}} =
2\max\left\{2,\left\lceil\frac{\texttt{current\_n}}{2}\right\rceil,
n_{\mathrm{arm}}\right\}.
\]

The result is even, gives equal group sizes, includes at least two participants per arm, and does not decrease the supplied total. It assumes no dropout, loss to follow-up, unequal allocation, or multiplicity adjustment. A finite-sample two-sample *t* test may need a different total; compare a real design against an appropriate power calculation such as [R's `power.t.test()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/power.t.test.html).

## Interpretation of an interim estimate

A raw interim effect estimate is not a substitute for a planned adaptive analysis. Choosing the final sample size from unblinded interim data and applying the original fixed-sample test can change the type I error rate; the output does **not** establish conditional power or a calibrated decision rule. Pre-specify any interim timing, adaptation rule, maximum size, final test, and error control. See the [research on interim sample-size changes](https://pmc.ncbi.nlm.nih.gov/articles/PMC4836563/) and the [group-sequential design guide](sequential.md).

The previous implementation omitted the two-arm variance factor. **Recompute previously reported totals** using the stated interpretation of `effect` and `variance`. The example above previously returned 50; it now returns 126. See [limitations and validation](limitations.md) for project-wide constraints.
