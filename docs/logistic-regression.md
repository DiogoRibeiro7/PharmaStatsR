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

The log odds are linear in the specified predictors. For a numeric 0/1 outcome,
`glm()` models the probability of 1; for a two-level factor, it models the
probability of the second level. For an unordered predictor factor under default treatment contrasts, the
first level is the reference. Ordered factors use different default
contrasts. Specify levels and contrasts explicitly before fitting and
confirm which event is being modeled.

## Fixed two-group reference

The [reference test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-logistic-reference.R)
uses 12 independent Bernoulli observations per group, with numeric 1 as the
event and `control` as the treatment baseline:

| Treatment | Events (1) | Non-events (0) | Denominator |
| --- | ---: | ---: | ---: |
| control | 4 | 8 | 12 |
| active | 9 | 3 | 12 |

The expected intercept is `log(4/8)`, the active coefficient is
`log((9/3)/(4/8)) = log(6)`, and the two fitted event probabilities are
`4/12` and `9/12`. The corresponding standard errors follow from the
binomial table: `sqrt(1/4 + 1/8)` for the intercept and
`sqrt(1/4 + 1/8 + 1/9 + 1/3)` for the log odds ratio. These targets are
computed from counts and information, without using a second wrapper fit.
The test also reverses outcome coding and the predictor baseline to check
coefficient signs, and checks factor outcome coding.

For missing model values, the wrapper passes `na.action` to `glm()`.
The fixture explicitly uses `na.omit` and verifies that one missing outcome
and one missing treatment drop exactly two rows; a missing unrelated column
does not. The same rows fail with `na.fail`. Review the chosen analysis
population, the unit of observation, and the adequacy of the predictors.
Independent observations, adequate events, and absence of complete or near
separation matter for coefficient inference. The table reference and earlier
[class/family smoke test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-pharma_tests.R)
do not establish calibration, causal interpretation, or validity for other
designs. See the [method inventory](method-inventory.md) and
[limitations](limitations.md).
