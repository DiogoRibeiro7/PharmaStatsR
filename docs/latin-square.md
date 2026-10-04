# Latin square ANOVA

`pharma_latin_square_anova()` fits an additive model for one complete Latin square. Each treatment occurs once in every row and column, with one response in each row-column cell. The row and column factors block two sources of variation:

\[
Y_{ij} = \mu + \tau_{t(i,j)} + \rho_i + \kappa_j + \varepsilon_{ij}.
\]

The treatment term compares means after accounting for the two blocking factors. The function requires at least three levels of each factor and checks the complete allocation before calling `stats::aov()`.

```r
library(PharmaStatsR)

fit <- pharma_latin_square_anova(
  response ~ treatment + row + column,
  data = pharma_latin_square
)
summary(fit)
```

## Fixed numerical reference

The [reference test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-design-anova-references.R) uses a cyclic 3 × 3 square. Treatment means are 7, 10, and 13; row means are 9, 10, and 11; column means are 8, 10, and 12. Each level occurs three times. The residual matrix has rows `(1, -1, 0)`, `(0, 1, -1)`, and `(-1, 0, 1)`. Its sums are zero in every row, column, and treatment, with squared sum 6.

| Source | Degrees of freedom | Sum of squares | Mean square | F |
| --- | ---: | ---: | ---: | ---: |
| Treatment | 2 | 54 | 27 | 9 |
| Row | 2 | 6 | 3 | 1 |
| Column | 2 | 24 | 12 | 4 |
| Residual | 2 | 6 | 3 | — |

The treatment C minus A coefficient is 6. The expected treatment sum of squares is `3 × (3² + 3²) = 54`; the row and column targets follow from their stated means, independent of `aov()`. This small square is a software reference. Its two residual degrees of freedom and unreplicated cells do not establish treatment efficacy or interaction behavior.

The bundled `pharma_latin_square` data have factor columns for treatment, row, and column. Numeric IDs must be converted explicitly: otherwise `aov()` would fit a quantitative trend instead of a categorical block effect.

```r
coded <- pharma_latin_square
coded$row <- as.integer(coded$row)
coded$column <- as.integer(coded$column)

fit <- pharma_latin_square_anova(
  response ~ treatment + factor(row) + factor(column),
  data = coded
)
```

## Interpretation and limits

The model includes three main effects and an intercept. It rejects interactions, incomplete or repeated cells, repeated treatments within a row or column, missing values, and non-finite responses. A single unreplicated square cannot estimate treatment-by-block interactions separately from error. The usual F test also relies on independent errors with common variance and an appropriate error distribution; inspect the residuals and the study design before interpreting it. `subset`, `weights`, and `na.action` cannot be passed through this helper because they can change the checked design or analysis population. Prepare a complete square in `data` first.

For background, see [Penn State's Latin square design lesson](https://online.stat.psu.edu/stat502/Lesson07) and [R's `aov()` documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/aov.html). See also [limitations and validation](limitations.md).

## R help

Full arguments and return values: [`pharma_latin_square_anova()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_latin_square_anova.Rd). In an installed package, run `help("pharma_latin_square_anova", package = "PharmaStatsR")`.
