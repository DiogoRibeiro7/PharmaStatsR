# Two-period crossover ANOVA

`pharma_crossover_anova()` fits an additive ANOVA for a complete, balanced two-treatment, two-period **AB/BA** design. Each subject receives A in one period and B in the other; half receive A first. The fixed-subject model is

\[
Y_{ip} = \mu + s_i + \pi_p + \tau_{T(i,p)} + \varepsilon_{ip},
\]

where \(s_i\) is a subject effect, \(\pi_p\) is a period effect, and \(\tau_{T(i,p)}\) is the treatment effect. The treatment term compares responses within subjects after accounting for period.

```r
library(PharmaStatsR)

fit <- pharma_crossover_anova(
  response ~ treatment + period + subject,
  data = pharma_crossover
)
summary(fit)
```

The bundled data now use categorical treatment, period, and subject variables, with five subjects in each sequence. An earlier version assigned A/A to five subjects and B/B to five others. In that arrangement treatment was confounded with subject, so results from the old fixture should be rechecked.

Numeric subject or period IDs must be converted to factors. Numeric inputs to `stats::aov()` would otherwise be fitted as quantitative predictors.

```r
coded <- pharma_crossover
coded$period <- as.integer(coded$period)
coded$subject <- as.integer(coded$subject)

fit <- pharma_crossover_anova(
  response ~ treatment + factor(period) + factor(subject),
  data = coded
)
```

## Interpretation and limits

The helper checks exactly two observed treatments and periods, at least four subjects, one record per subject and period, both treatments for every subject, and equal AB and BA sequence counts. It rejects missing and non-finite model values and additional terms. Prepare a complete analysis dataset first; `subset`, `weights`, and `na.action` cannot be passed through the helper.

This model does not estimate a separate sequence effect because sequence is constant within subject. Differential carryover can bias the treatment comparison in a two-period AB/BA study; assess washout and whether this design is appropriate before interpreting its F test. It does not establish bioequivalence or handle missing second-period outcomes. See [Penn State's crossover design lesson](https://online.stat.psu.edu/stat509/Lesson12), [R's `aov()` documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/aov.html), and [project limitations](limitations.md).

## R help

Full arguments and return values: [`pharma_crossover_anova()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_crossover_anova.Rd). In an installed package, run `help("pharma_crossover_anova", package = "PharmaStatsR")`.
