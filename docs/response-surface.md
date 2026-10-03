# Two-predictor response surface

`pharma_response_surface()` fits an ordinary least-squares quadratic in two numeric predictors. Its six coefficients represent an intercept, two linear terms, two squared terms, and one interaction:

\[
Y_i = \beta_0 + \beta_1 x_{1i} + \beta_2 x_{2i} + \beta_{11}x_{1i}^2 + \beta_{22}x_{2i}^2 + \beta_{12}x_{1i}x_{2i} + \varepsilon_i.
\]

Use a design with enough distinct predictor combinations to estimate all six terms. The bundled `pharma_dose_response` has only one dose predictor: passing `dose` as both inputs makes the quadratic design singular. This example instead uses a crossed three-by-three grid with two observations at each point:

```r
library(PharmaStatsR)

grid <- expand.grid(x1 = c(-1, 0, 1), x2 = c(-1, 0, 1), replicate = 1:2)
grid$y <- 10 + 2 * grid$x1 - 3 * grid$x2 + 4 * grid$x1^2 +
  5 * grid$x2^2 + 6 * grid$x1 * grid$x2 +
  ifelse(grid$replicate == 1, -1, 1)

fit <- pharma_response_surface(grid$x1, grid$x2, grid$y)
summary(fit)
predict(fit, newdata = data.frame(x1 = 0.5, x2 = -0.5))
```

The constructed coefficients are \((10,2,-3,4,5,6)\). Paired errors of \(-1\) and \(+1\) at every design point cancel in the fitted means. There are 18 observations and six coefficients, so the residual sum of squares is 18 on 12 degrees of freedom; the residual mean square is 1.5. The fitted response at \((0.5,-0.5)\) is 13.25. [The numerical test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-response-surface.R) also compares the coefficients with an explicit least-squares design matrix and a direct `stats::lm()` fit.

## Input and interpretation

- `x1`, `x2`, and `y` must be finite numeric vectors of equal length. At least seven observations and a full-rank six-column quadratic design are required. Duplicated design points are accepted when the overall matrix has full rank; matching or linearly related predictors generally fail this check.
- Missing and infinite values are rejected. Prepare the analysis rows before calling the helper. `subset`, `weights`, `na.action`, `offset`, `method`, and `singular.ok` are unsupported; any other arguments to `stats::lm()` must be named.
- The result is an `lm` fit. Residual variance supports the usual coefficient tests only under appropriate independent-error, variance, and distribution assumptions. Repeated design points can support a separate pure-error and lack-of-fit analysis, but this helper does not compute that decomposition. Without replication, its residual sum of squares can include lack of fit. Centering and scaling predictors may improve numerical stability; interpret coefficients in the scale used for fitting.

Earlier calls that supplied the same vector for both predictors could return aliased coefficients. Rebuild a design with two varied predictors and recompute those fits. See the [method inventory](method-inventory.md) and [limitations](limitations.md) for review scope.

## R help

Full arguments and return values: [`pharma_response_surface()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_response_surface.Rd). In an installed package, run `help("pharma_response_surface", package = "PharmaStatsR")`.
