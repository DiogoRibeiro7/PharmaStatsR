# Wild bootstrap coefficient draws

`pharma_wild_bootstrap()` returns coefficient draws from an ordinary least-squares fit. The model matrix stays fixed. For each draw, the function independently changes the sign of each fitted residual and refits the response, with any formula offset retained:

\[
y_i^*=\widehat y_i+\widehat e_i v_i,\qquad
P(v_i=-1)=P(v_i=1)=\tfrac12.
\]

The output has one row per draw and named columns matching `coef(lm(...))`. Set a seed to reproduce the signs.

```r
library(PharmaStatsR)

set.seed(42)
draws <- pharma_wild_bootstrap(
  response ~ treatment, data = pharma_sample, R = 500
)
head(draws)
```

The response must be a finite numeric vector; the formula must be two-sided and all referenced variables must be in `data`. Transformed terms, factors, and formula offsets use the model frame and matrix from the original fit. Missing values in any **model variable** cause an error, while missing values in unrelated columns do not. The design must have full column rank and at least one residual degree of freedom. `R` must be a positive whole number.

## Interpretation

These are draws of the **unstudentized coefficients**, using raw residuals and observation-level Rademacher signs. The helper does not return confidence intervals or p-values, impose a null hypothesis, rescale residuals for leverage, or account for dependence between observations. Its sign draws assume independent observational units; use an appropriate cluster-aware design for clustered or repeated measurements. Interval coverage and test calibration depend on the model and chosen bootstrap procedure. See [limitations and validation](limitations.md).

R documents how [`lm()` builds model frames and applies offsets](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/lm.html); [Davidson and Flachaire (2008)](https://russell-davidson.research.mcgill.ca/articles/wild8-euro.pdf) discuss wild bootstrap versions and inference under heteroskedasticity.
