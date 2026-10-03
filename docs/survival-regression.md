# Cox and parametric survival regression

`pharma_survival_fit()` delegates to `survival::coxph()`, and `pharma_parametric_survival()` delegates to `survival::survreg()`. For the right-censored examples below, `time` is duration from a defined origin, `status = 1` denotes the event of interest, and `status = 0` denotes censoring. Define the event and time units before fitting either model.

```r
library(PharmaStatsR)

formula <- survival::Surv(time, status) ~ treatment
cox <- pharma_survival_fit(formula, pharma_survival)
weibull <- pharma_parametric_survival(formula, pharma_survival)

cox$n
length(weibull$linear.predictors)
cox$na.action
weibull$na.action
summary(cox)
summary(weibull)
```

Both helpers pass `subset` and `na.action` to their respective `survival` backends through `...`. The backend may omit rows with missing model variables. Check the selected population in the fit and record exclusions before comparing results. Cox fits can select a tie method, such as `ties = "breslow"`; use the same method in a reference calculation. For changing covariates represented by `(start, stop]` records, see [time-varying Cox analysis](cox-timevarying.md). For a fixed risk set after a prespecified time, see [landmark Cox analysis](landmark-analysis.md).

## Interpret the parameters separately

The Cox model estimates coefficients on the log hazard-ratio scale under a proportional-hazards model. For a one-unit covariate difference, `exp(coef(cox))` gives a conditional hazard ratio. It does not give a survival-time ratio.

The default Weibull `survreg()` model uses an accelerated failure-time parameterization. For a covariate coefficient, `exp(coef(weibull))` gives a model-based ratio of survival time scales, **not** a Cox hazard ratio. The fitted `weibull$scale` is the reciprocal of the usual Weibull shape; the intercept determines the reference group's log time scale. Other `dist` choices have their own interpretation. The [survival distribution documentation](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/survreg.distributions.html) describes this mapping.

## Reference and limits

The [test fixture](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-survival-regression-reference.R) includes a factor predictor, ties, selected rows, and missing covariates. It compares both wrappers with direct backend calls on the same analysis population. For an intercept-only exponential model with no censoring, it also checks that the fitted mean event time equals the sample mean.

These are software reference cases. A fitted model does not verify independent censoring, proportional hazards for Cox, or a suitable Weibull distribution. Competing events require explicit cause coding and a different estimand; see [competing risks](competing-risks.md). The [limitations guide](limitations.md) records the wider package scope.

## R help

Full arguments and return values:

- [`pharma_survival_fit()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_survival_fit.Rd)
- [`pharma_parametric_survival()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_parametric_survival.Rd)

In an installed package, run `help(package = "PharmaStatsR")` to open the corresponding topics.
