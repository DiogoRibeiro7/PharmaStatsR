# Group-sequential efficacy boundaries

`pharma_group_seq()` returns critical z-values for a planned sequence of analyses under the **canonical joint normal model**. It uses [gsDesign](https://keaven.github.io/gsDesign/reference/gsDesign.html) to calibrate O'Brien–Fleming or Pocock boundaries for a symmetric two-sided design.

```r
library(PharmaStatsR)

# Three analyses at one-third, two-thirds, and full information.
of <- pharma_group_seq(k = 3, alpha = 0.05)
pocock <- pharma_group_seq(k = 3, alpha = 0.05, method = "pocock")
of
pocock

# Specify planned information fractions when they are not equally spaced.
pharma_group_seq(k = 3, timing = c(0.25, 0.6, 1))
```

`k` counts **all** analyses, including the final analysis. `alpha` is the overall two-sided error rate; `timing` represents cumulative information fractions and must increase to 1. The function returns positive upper z-boundaries, with symmetric negative lower boundaries. An absolute z-statistic crosses at an analysis when it reaches that analysis's boundary, provided the trial has not already stopped.

The previous implementation used expressions that did not calibrate these boundary families. In particular, its early “O'Brien–Fleming” boundary was too low and its “Pocock” boundary was a Bonferroni threshold. **Recompute any design or decision that used earlier outputs.**

These critical values rely on the planned analysis schedule and joint normal assumptions. The helper does not supply a futility rule, an endpoint-specific test statistic, information estimation, sample size, a monitoring plan, or regulatory validation. For an actual study, specify these components before data inspection and review the full design with a statistician. See [limitations](limitations.md).

## R help

Full arguments and return values: [`pharma_group_seq()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_group_seq.Rd). In an installed package, run `help("pharma_group_seq", package = "PharmaStatsR")`.
