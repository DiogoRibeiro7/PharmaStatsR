# Logistic regression

`pharma_logistic_regression()` delegates to `stats::glm()` with a binomial family and logit link. It returns the fitted `glm` object, so use `summary()`, `coef()`, and `predict()` as for a standard binomial GLM. The full argument contract is in [the installed help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_logistic_regression.Rd); `...` passes through to `glm()`, but the wrapper fixes `family = stats::binomial()`.

```r
library(PharmaStatsR)

fit <- pharma_logistic_regression(outcome ~ treatment, data = pharma_sample)
summary(fit)
stats::predict(fit, type = "response")
```

The bundled `outcome` is an arbitrary binary label, not a defined clinical event. In `pharma_sample`, treatment and dose are perfectly confounded, so the example cannot estimate their separate effects. Predictions above are fitted probabilities for the coded outcome; they are not treatment effects or calibrated clinical risks.

## Interpretation and checks

The log odds are linear in the specified predictors. Review the outcome coding, the unit of observation, missing-row handling by `glm()`, and the adequacy of the chosen predictors. Independent observations, adequate events, and absence of complete or near separation matter for coefficient inference. A successful fit and the [class/family smoke test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-pharma_tests.R) do not establish calibration, causal interpretation, or independent numerical validation. See the [method inventory](method-inventory.md) and [limitations](limitations.md).
