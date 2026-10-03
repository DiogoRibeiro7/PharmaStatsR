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

The [inventory](method-inventory.md) records an installed-backend class smoke test and a missing-backend guard. These tests do not provide an independent numerical reference, confirm a particular random-effects structure, or validate an analysis for a study.
