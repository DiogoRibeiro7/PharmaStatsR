# Model diagnostics

`pharma_model_diagnostics()` reports residuals, standardized residuals, Cook's distance, leverage, and a screening flag for each observation available from a fitted univariate `lm` or `glm`.

```r
library(PharmaStatsR)

fit <- lm(response ~ treatment, data = pharma_sample)
diagnostics <- pharma_model_diagnostics(fit)
head(diagnostics)
subset(diagnostics, flag %in% TRUE)
```

## Measures and cutoffs

| Output | Meaning |
| --- | --- |
| `residual` | The fitted model's default residual: ordinary for `lm`, deviance for `glm`. |
| `std_resid` | `stats::rstandard(fit)`: standardized residuals (Pearson by default for `glm`). |
| `cook_d` | `stats::cooks.distance(fit)`: change in fitted model associated with deleting one observation. |
| `leverage` | `stats::hatvalues(fit)`: diagonal of the model's hat matrix. |
| `flag` | `abs(std_resid) > threshold` or `cook_d > cook_cutoff`. |

The default residual threshold is 3 and the default Cook cutoff is \(4/n_{\mathrm{fit}}\), with \(n_{\mathrm{fit}}=\texttt{stats::nobs(fit)}\). Change the Cook rule if a different descriptive screen is appropriate:

```r
pharma_model_diagnostics(fit, threshold = 2.5, cook_cutoff = 0.5)
```

Both cutoffs must be finite positive scalars. If the model used `na.exclude`, R can restore excluded positions as missing diagnostic values; their flags remain `NA`. The fitted observation count excludes these rows. [R's regression diagnostics](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/influence.measures.html) define the measures, and [`nobs()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/nobs.html) counts observations used in the fit.

## Independent ordinary least-squares reference

The self-contained [numerical reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-model-diagnostics-reference.R) use six synthetic observations and an unweighted model `y ~ x`. Expected values come from fixed normal-equation arithmetic, not from the `stats` diagnostic methods called by the wrapper.

### Fixture and derivation

| Case | x | y | Residual e | Leverage h | Standardized residual r | Cook's distance D |
| --- | --- | --- | --- | --- | --- | --- |
| case-01 | -3 | 0 | 1 | 37/60 | sqrt(30/23) | 555/529 |
| case-02 | -1 | -1 | -2 | 13/60 | -sqrt(120/47) | 780/2209 |
| case-03 | 0 | 3 | 1 | 1/6 | sqrt(3/5) | 3/50 |
| case-04 | 0 | 1 | -1 | 1/6 | -sqrt(3/5) | 3/50 |
| case-05 | 1 | 4 | 1 | 13/60 | sqrt(30/47) | 195/2209 |
| case-06 | 3 | 5 | 0 | 37/60 | 0 | 0 |

Let \(X\) have an intercept column and the stated predictor. Then

\[
X^\top X=\begin{pmatrix}6&0\\0&20\end{pmatrix},\qquad
X^\top y=\begin{pmatrix}12\\20\end{pmatrix},\qquad
\widehat\beta=\begin{pmatrix}2\\1\end{pmatrix}.
\]

Thus \(\widehat y_i=2+x_i\), \(e=(1,-2,1,-1,1,0)^\top\), and \(e^\top e=8\). There are \(n=6\) fitted observations and \(p=2\) fitted coefficients, so the residual variance estimate is \(s^2=8/(6-2)=2\). The hat matrix and diagnostics are

\[
H=X(X^\top X)^{-1}X^\top,\qquad
h_i=\frac16+\frac{x_i^2}{20},\qquad
r_i=\frac{e_i}{s\sqrt{1-h_i}},\qquad
D_i=\frac{e_i^2}{p s^2}\frac{h_i}{(1-h_i)^2}.
\]

These are internally standardized residuals using the full-fit residual variance, not externally Studentized residuals with a separate case-deleted variance. Cook's distance also equals

\[
D_i=\frac{(\widehat\beta_{(-i)}-\widehat\beta)^\top
X^\top X(\widehat\beta_{(-i)}-\widehat\beta)}{p s^2},
\]

where \(\widehat\beta_{(-i)}\) is the coefficient vector with observation \(i\) deleted. The reference was independently checked with exact SymPy arithmetic and a separate NumPy QR/case-deletion calculation; the numeric checks agreed within absolute tolerance `1e-12`. Neither obtains expected values from an R diagnostic method.

A base-R calculation reproduces the targets without fitting another model:

```r
x <- c(-3, -1, 0, 0, 1, 3)
y <- c(0, -1, 3, 1, 4, 5)
e <- y - (2 + x)
h <- 1 / 6 + x^2 / 20
s2 <- sum(e^2) / 4
r <- e / sqrt(s2 * (1 - h))
d <- e^2 * h / (2 * s2 * (1 - h)^2)
data.frame(residual = e, std_resid = r, cook_d = d, leverage = h,
           flag = abs(r) > 3 | d > 4 / 6)
```

### Cutoffs, row identity, and missing observations

At the default cutoffs, only `case-01` is flagged: its Cook's distance is approximately `1.0491`, above `4/6`. The largest absolute standardized residual is approximately `1.5979`, below 3. `case-06` has high leverage but a zero residual and zero Cook's distance, so leverage alone does not flag it.

A residual cutoff of `1.5` with a Cook cutoff of `100` flags only `case-02`. A residual cutoff of `100` with a Cook cutoff of `0.8` flags only `case-01`; using `1.5` and `0.8` together flags both. Separate comparison-contract tests set each cutoff exactly to the corresponding returned floating-point maximum and confirm that equality is not flagged. Reducing that cutoff by a relative `1e-8` flags the expected case. Reusing a returned number here establishes exact equality for the comparison; it is not used to generate the independent diagnostic targets.

For the row-selection reference, six observations with missing responses and two complete excluded observations are interleaved with the original six cases. The original model's subset removes the two complete exclusions. `na.omit` returns diagnostics for the six fitted cases; `na.exclude` restores the six missing-response positions, with missing measures and `NA` flags. Named rows retain their original selected order.

The Cook cutoff must still be `4/6`, not `4/12`. This matters numerically: `case-02` has \(D_2=780/2209\approx0.3531\), strictly between `4/12` and `4/6`. A cutoff incorrectly based on the padded output would change its flag. Subset-excluded rows must not reappear in either output.

### Transformations and evidence limits

The tests also apply `y_star = 7 + b * y` for `b = 2` and `b = -2`. Raw residuals multiply by `b`, standardized residuals multiply by its sign, and leverage, Cook's distance, and default flags remain unchanged. A fixed row permutation checks the same targets by case identity. These transformations preserve the intercept-containing, unweighted design used here.

Numerical assertions use `testthat::expect_equal()` with tolerance `1e-12`; row names, column names, and logical flags use exact comparisons. This is a numerical comparison tolerance, not a confidence bound. No random sampling or optional dependency is needed. The existing [contract and input-validation tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-model-diagnostics.R) remain unchanged.

This reference covers complete, full-rank, unweighted univariate `lm` fits and the stated subset/missing-row variants. It does not independently validate GLM diagnostics, weighted or rank-deficient fits, statistical outlier tests, or decisions to delete observations. It introduces no production behavior or API change; the statistical support level remains experimental.

## Interpreting a flag

A `TRUE` flag means that at least one screening cutoff was exceeded. It does not prove a data error, justify removing that row, or validate the fitted model. Inspect the original observation, fit assumptions, and sensitivity of the result before deciding whether any change is warranted. Standardized and Cook diagnostics for `glm` are approximations, especially when points are highly influential. A multivariate `lm` does not have one scalar diagnostic per row and is rejected.

## R help

Full arguments and return values: [`pharma_model_diagnostics()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_model_diagnostics.Rd). In an installed package, run `help("pharma_model_diagnostics", package = "PharmaStatsR")`.
