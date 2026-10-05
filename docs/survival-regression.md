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

## Independent ordinary Cox reference

The hand-constructed fixture in [test-cox-partial-likelihood-reference.R](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-cox-partial-likelihood-reference.R) uses the observations from the [Kaplan–Meier reference](kaplan-meier.md). Here group A is `control`, group B is `active`, and the only covariate is \(x=1\) for active and \(x=0\) for control. The test fixes treatment contrasts with control as the reference, independently of the session's contrast options. These are illustrative observations, not clinical data.

| Group | `(time, status)` observations |
| --- | --- |
| Control, \(x=0\) | `(1, 1), (2, 1), (2, 0), (3, 1), (5, 0), (6, 1)` |
| Active, \(x=1\) | `(1, 0), (2, 1), (3, 1), (3, 0), (4, 1), (6, 0)` |

There are 12 subjects, seven events, and no delayed entry. Subjects censored at an event time remain in that time's risk set. All events and censorings at that time leave the risk set before the next time. The event-time risk counts \(n_0,n_1\) and event counts \(d_0,d_1\) are:

| Event time | \(n_0\) | \(n_1\) | \(d_0\) | \(d_1\) |
| --- | --- | --- | --- | --- |
| 1 | 6 | 6 | 1 | 0 |
| 2 | 5 | 5 | 1 | 1 |
| 3 | 3 | 4 | 1 | 1 |
| 4 | 2 | 2 | 0 | 1 |
| 6 | 1 | 1 | 1 | 0 |

The censoring at time 5 contributes no likelihood term, but removes a control subject before the final event. Tied events occur at times 2 and 3. Fit `Surv(time, status) ~ treatment` without weights, strata, or clustering, using `robust = FALSE` for the model-based variance. The [Cox backend documentation](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/coxph.html) describes these options and the ordinary single-event Efron default.

### Breslow: a closed-form coefficient

Write \(r=\exp(\beta)\) for the active-versus-control hazard ratio and \(d_j=d_{0j}+d_{1j}\). The Breslow partial log likelihood from the risk table is

\[
\ell_B(\beta)=\sum_j\left\{d_{1j}\beta-d_j\log(n_{0j}+n_{1j}r)\right\}
=3\beta-\log(300)-5\log(1+r)-2\log(3+4r).
\]

Its score and observed information are

\[
U_B(\beta)=3-\frac{5r}{1+r}-\frac{8r}{3+4r},\qquad
I_B(\beta)=\frac{5r}{(1+r)^2}+\frac{24r}{(3+4r)^2}.
\]

The score equation reduces to \(16r^2+2r-9=0\), so the positive solution is

\[
\widehat r_B=\frac{\sqrt{145}-1}{16},\qquad
\widehat\beta_B=\log(\widehat r_B).
\]

No numerical optimizer is needed for this coefficient. Information is positive for \(r>0\), and the score goes from 3 to -4 as \(\beta\) goes from negative to positive infinity. Thus the finite stationary point is the unique maximum.

### Efron: an independent tie-rule check

For Efron ties, the denominators at event time \(j\) are

\[
D_{jk}=n_{0j}+n_{1j}r-\frac{k}{d_j}(d_{0j}+d_{1j}r),
\qquad k=0,\ldots,d_j-1.
\]

Substituting the same risk table and differentiating gives

\[
\ell_E(\beta)=3\beta-\log(135)-5\log(1+r)
-\log(3+4r)-\log(5+7r),
\]

\[
U_E(\beta)=3-\frac{5r}{1+r}-\frac{4r}{3+4r}-\frac{7r}{5+7r},
\]

\[
I_E(\beta)=\frac{5r}{(1+r)^2}+\frac{12r}{(3+4r)^2}
+\frac{35r}{(5+7r)^2}.
\]

The positive root of \(112r^3+95r^2-52r-45=0\) gives \(\widehat r_E\). The score is strictly decreasing with the same limits as the Breslow score, so this is also a unique finite maximum. Its slightly different coefficient makes the fixture sensitive to an ignored `ties` option. Both coefficients can be reproduced without `coxph()`:

```r
r_breslow <- (sqrt(145) - 1) / 16
r_efron <- stats::uniroot(
  function(r) 112 * r^3 + 95 * r^2 - 52 * r - 45,
  interval = c(0.5, 1), tol = 1e-12
)$root
log(c(breslow = r_breslow, efron = r_efron))
```

### Uncertainty and likelihood targets

The model-based variance of the log hazard ratio is \(I(\widehat\beta)^{-1}\), its standard error is \(I(\widehat\beta)^{-1/2}\), and the 95% Wald interval is \(\widehat\beta\pm z_{0.975}\operatorname{SE}(\widehat\beta)\). Exponentiating its endpoints produces the hazard-ratio interval. These are not robust sandwich variances.

| Quantity | Breslow | Efron |
| --- | --- | --- |
| Log hazard ratio \(\widehat\beta\) | -0.3709192553359674 | -0.3780599269349066 |
| Hazard ratio \(\widehat r\) | 0.6900996611745185 | 0.6851894381326490 |
| Information \(I(\widehat\beta)\) | 1.7071078394690232 | 1.7057595599300345 |
| Variance | 0.5857860744819957 | 0.5862490959986279 |
| Standard error | 0.7653666274942981 | 0.7656690512216279 |
| \(\ell(0)\) | -13.0613386755665542 | -12.8018274800814696 |
| \(\ell(\widehat\beta)\) | -12.9424910951151456 | -12.6784431161375415 |
| 95% log hazard-ratio interval | (-1.8710102801936754, 1.1291717695217406) | (-1.8787436914062513, 1.1226238375364381) |

The fixed targets were calculated from the displayed likelihood and derivatives, with a closed-form Breslow root and an independent high-precision scalar solution for Efron. No target was copied from a `survival` fit. The tests compare the returned coefficient, covariance, summary standard error, exponentiated effect, and interval with these targets. They also evaluate the independent score and likelihood at the fitted coefficient. Coefficient and uncertainty checks use a `1e-7` tolerance, fitted likelihood checks use `1e-9`, and the fitted score must have absolute value below `1e-7`. The [returned Cox object](https://stat.ethz.ch/R-manual/R-devel/library/survival/html/coxph.object.html) stores initial and fitted partial log likelihoods; these are not full event-time likelihoods.

### Analysis-population boundaries

For each tie method, three complete decoy rows are excluded with `subset = selected`. Three selected rows with a missing time, status, or treatment are then removed using either `na.omit` or `na.exclude`. The tests require the original 12 named subjects, seven events, event/covariate vectors, and numerical targets. `na.fail` must reject the selected incomplete records; this assertion does not depend on optimizer warning text. Reversing input-row order must preserve the targets. A separate call without `ties` must match the Efron reference.

## Reference and limits

The existing [backend-comparison fixture](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-survival-regression-reference.R) includes a factor predictor, ties, selected rows, and missing covariates. It compares both wrappers with direct backend calls on the same analysis population. For an intercept-only exponential model with no censoring, it also checks that the fitted mean event time equals the sample mean. Those checks remain alongside the independent ordinary Cox reference.

The independent Cox calculation covers one binary predictor, ordinary unweighted right-censored single-event observations, exact ties, and model-based uncertainty. It does not independently validate robust variances, baseline hazards or survival predictions, exact tie likelihoods, near-tie correction, multivariable or penalized models, time-varying Cox, landmark analysis, or competing risks. Checking Wald-interval construction does not establish its small-sample coverage. The statistical API remains experimental.

These are software reference cases. A fitted model does not verify an independent-subject sampling model, appropriate independent censoring conditional on included covariates, proportional hazards for Cox, or a suitable Weibull distribution. Competing events require explicit cause coding and a different estimand; see [competing risks](competing-risks.md). The [limitations guide](limitations.md) records the wider package scope.

## R help

Full arguments and return values:

- [`pharma_survival_fit()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_survival_fit.Rd)
- [`pharma_parametric_survival()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_parametric_survival.Rd)

In an installed package, run `help(package = "PharmaStatsR")` to open the corresponding topics.
