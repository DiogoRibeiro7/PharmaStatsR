# Complete-case LASSO screening

`screen_covariates_lasso()` returns the original numeric candidate names with
nonzero fitted coefficients at `lambda.min`, in candidate order. It requires at
least two candidate columns. Rows missing the response or any candidate are
removed together before fitting; unused columns do not determine this cohort.

The model uses Gaussian regression. The default `alpha = 1` is LASSO; values
between zero and one use elastic net, and zero gives ridge. The helper retains
[`glmnet()`](https://search.r-project.org/CRAN/refmans/glmnet/html/glmnet.html)
defaults for predictor standardization, the fitted intercept and automatic
penalty path. Ridge generally does not produce sparse coefficients. Selection
uses an exact nonzero comparison, without an additional coefficient tolerance.

## Folds and interpretation

By default, random folds split rows. Use `id` to keep each retained subject in
one fold, and set the R seed for reproducible random assignments. Grouping changes
the split, not the regression's correlation model. Alternatively, provide one
positive integer `foldid` label per original row. Those labels are filtered with
the model rows and renumbered; at least three folds must remain. An explicit
split takes precedence over `nfolds` and avoids random fold generation.

[`cv.glmnet()`](https://search.r-project.org/CRAN/refmans/glmnet/html/cv.glmnet.html)
selects `lambda.min` from the minimum mean held-out squared error on its path.
The helper uses that choice, not `lambda.1se`. Its automatic grid is data-derived;
CV error used for tuning is not an independent estimate of final performance.
Transformations or imputations supplied before the call are not refitted inside
folds. For saved training-fold preprocessing, explicit penalty grids and returned
predictions, use the [imputed-LASSO workflow](lasso-imputation.md).

## Independent coefficient and CV reference

Each eight-row block below has orthogonal, centered `u`, `v` and `error` columns,
with mean square one. There are three identical blocks, one per validation fold.
Every training split therefore has the same means and inner products.

```r
library(PharmaStatsR)
u <- rep(c(-1, 1), 4)
v <- rep(c(-1, -1, 1, 1), 2)
error <- rep(c(-1, 1), each = 4)
d <- data.frame(
  y = rep(3 + 2 * u + 0.5 * error, 3),
  signal = rep(u, 3), noise = rep(v, 3),
  id = rep(c("a", "b", "c"), each = 8)
)
folds <- rep(c(10L, 20L, 30L), each = 8)
screen_covariates_lasso(d, "y", c("signal", "noise"), id = "id", foldid = folds)
# [1] "signal"
```

With `alpha = 1` and these unit-scale orthogonal predictors, the Gaussian
penalized objective separates by coefficient. Soft thresholding gives

\[
\widehat\beta_{signal}(\lambda)=\max(2-\lambda,0),\qquad
\widehat\beta_{noise}(\lambda)=0,\qquad \widehat\beta_0=3.
\]

Thus each held-out prediction is `3 + signal * max(2 - lambda, 0)`.
The orthogonal residual component contributes 0.25 to MSE, giving

\[
MSE(\lambda)=0.25+[2-\max(2-\lambda,0)]^2.
\]

These are illustrative formula values, not a penalty grid passed to the helper:

| Penalty | Signal coefficient | Held-out MSE |
| ---: | ---: | ---: |
| 2 | 0 | 4.25 |
| 1 | 1 | 1.25 |
| 0.5 | 1.5 | 0.5 |

The generated path begins at the zero-coefficient threshold of 2. On this
fixture the error decreases along the path, so `lambda.min` is its smallest
returned value. The backend can truncate its path; the tests do not fix its
length or lowest penalty across versions.

The tests retain the backend's actual held-out predictions, then compare the
full coefficient path, those predictions, CV means and the chosen penalty with
these independent formulas at the returned penalty values. Negative effects and
two active predictors have corresponding soft-threshold references. Missing-row
and fold-label alignment, literal names, candidate order and changed units are
also checked. The analytic evidence is scoped to Gaussian `alpha = 1` with these
balanced orthogonal fixtures; it does not establish all elastic-net or
correlated-design behavior.

## Literal names and migration

Column names are literal strings, including spaces, formula operators and
`(Intercept)`:

```r
names(d)[2] <- "(Intercept)"
screen_covariates_lasso(d, "y", c("(Intercept)", "noise"), foldid = folds)
# [1] "(Intercept)"
```

Earlier versions removed all coefficient rows named `(Intercept)`, silently
omitting a candidate with that name even when its coefficient was nonzero.
The helper now excludes only the fitted intercept and matches the remaining
coefficients to the input columns. The same case with a zero candidate
coefficient still omits that candidate. Recompute affected selections.

The signature, fitting defaults, fold construction and character-vector return
are unchanged. There are no new exports, dependencies or version changes.
The method remains experimental. It does not model within-subject correlation,
perform categorical encoding, or provide post-selection inference. See the
[migration guide](covariate-migration.md) and [evidence inventory](method-inventory.md).
