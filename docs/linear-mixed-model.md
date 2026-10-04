# Linear mixed model

`pharma_lmm()` checks that `data` is a data frame and that the formula variables exist, then delegates the fit to `lme4::lmer()`. Install the optional `lme4` package before using it. The helper returns an `lmerMod` fit; it does not choose random effects or verify the data's repeated-measures design. See the [installed R help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_lmm.Rd) for its arguments and return value.

```r
library(PharmaStatsR)

dat <- pharma_repeated
dat$subject <- factor(dat$subject)
dat$condition <- factor(dat$condition)
fit <- pharma_lmm(response ~ condition + (1 | subject), data = dat)
summary(fit)
lme4::isSingular(fit)
```

The example has two hand-entered observations per subject. The formula estimates a condition contrast with a subject-specific intercept; it assumes the random-intercept structure describes the within-subject dependence. The subject labels are explicitly encoded as a factor, and the observations are illustrative rather than clinical records. This is a different model and test from the [paired two-condition ANOVA](repeated-anova.md).

## Interpretation and diagnostics

`lmer()` uses REML by default; pass `REML = FALSE` through `...` when a planned comparison of models with different fixed effects calls for ML fits. Review residual behavior, subject-level variation, singularity and convergence warnings, as well as the independence of subjects. The wrapper's initial validation checks only variable presence; it does not reject incomplete model rows or establish normal errors and random effects. The backend's own missing-data rules and fit diagnostics apply. See the [lme4 fit reference](https://lme4.github.io/lme4/reference/lmer.html) and [singularity reference](https://lme4.github.io/lme4/reference/isSingular.html).

## Balanced numerical reference

The [reference test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-lmm-reference.R)
uses eight subjects, each measured once under control and once under
active treatment. It assigns subject baseline offsets
(-1.4, -1, -0.6, -0.2, 0.2, 0.6, 1, 1.4) and paired treatment
departures (-0.3, -0.2, -0.1, 0, 0, 0.1, 0.2, 0.3).
Control responses equal `10 + offset - departure/2`; active responses
equal `12 + offset + departure/2`. Thus the mean control response is 10
and the mean within-subject active-minus-control contrast is 2,
independently of any model fit.

With default REML and the stated random-intercept model, the sample
variance of paired differences is 0.04, giving residual variance
`0.04/2 = 0.02`. The sample variance of subject means is 0.96, giving
random-intercept variance `0.96 - 0.02/2 = 0.95`. The contrast standard
error is `sqrt(0.04/8)`. The test compares these targets within numerical
tolerance and checks all 16 selected rows. A separate incomplete fixture
checks `na.omit` selects 15 model rows while an unrelated missing column
does not alter the fit population. A one-subject design is rejected by
`lme4` because it cannot estimate the specified grouping structure.

Population predictions use `predict(fit, re.form = NA)` and omit the
subject-specific intercept. Conditional predictions include the estimated
subject effect; the difference between conditions remains the fixed
contrast. Subject effects are shrunk estimates, not exact recovery of the
assigned offsets. Check `isSingular()`, convergence warnings, and model
assumptions for real data. The wrapper passes backend errors and warnings
through; it does not turn a singular or failed design into a validated
analysis. The [inventory](method-inventory.md) records this narrow
numerical reference alongside earlier class and backend-guard checks.
