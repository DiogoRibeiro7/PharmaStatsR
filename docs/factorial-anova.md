# Balanced two-factor ANOVA

`pharma_factorial_anova()` fits an ordinary fixed-effects model with two categorical factors and their interaction. For factor levels \(i,j\) and independent replicate \(k\), the fitted mean structure is \(Y_{ijk}=\mu+\alpha_i+\beta_j+(\alpha\beta)_{ij}+\varepsilon_{ijk}\). The helper requires every factor combination to occur **the same number of times, at least twice**. The residual variation then has positive degrees of freedom, and the ordinary sequential ANOVA tests are orthogonal for this balanced design.

```r
library(PharmaStatsR)

example <- data.frame(
  treatment = factor(rep(c("A", "B"), each = 4)),
  dose = factor(rep(c("Low", "High"), each = 2, times = 2)),
  response = c(9, 11, 11, 13, 10, 12, 16, 18)
)
fit <- pharma_factorial_anova(response ~ treatment * dose, example)
summary(fit)
```

The four cell means are 10, 12, 11, and 17 in row order (A/Low, A/High, B/Low, B/High). The treatment, dose, interaction, and residual sums of squares are 18, 32, 8, and 8; with four residual degrees of freedom, the F statistics are 9, 16, and 4. The interaction is a difference of differences: \((17-11)-(12-10)=4\). [The test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-factorial-anova.R) pins these values and independent F-distribution tails.

## Input and interpretation

- Use a two-sided formula with an intercept, both main effects, and their interaction: `response ~ factor1 * factor2`. Factors may have two or more observed levels. Factor, character, and logical predictors are accepted; wrap numeric codes in `factor()` explicitly.
- Every crossed cell needs the same number of observations, at least two. Missing values or non-finite responses error. `subset`, `weights`, `na.action`, and `offset` cannot change the checked population or model; prepare the full analysis data first.
- Main effects average over the other factor. Inspect the interaction and cell means before describing a main effect in isolation. The ordinary F reference assumes independent errors with a common within-cell variance and a suitable residual distribution. This helper does not model repeated measures, blocks, covariates, or an unbalanced design.

The bundled `pharma_sample` is **not** a factorial example: all A observations have dose 1 and all B observations have dose 2. Treatment and dose are confounded, so `response ~ treatment * factor(dose)` now errors on the absent crossed cells. Recheck earlier results fitted to that example; no independent treatment, dose, or interaction effect can be inferred from it. See [one-way ANOVA](anova.md) for a single group, the [method inventory](method-inventory.md) for review status, and [limitations](limitations.md) for project-wide constraints.
