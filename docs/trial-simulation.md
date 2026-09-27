# Two-arm trial simulation

`pharma_trial_simulate()` generates example subject-level time-to-event data. It assigns each subject to one of two arms independently with probability 1/2, so group sizes can differ. Use `set.seed()` when you need reproducible draws.

```r
library(PharmaStatsR)

set.seed(42)
trial <- pharma_trial_simulate(
  n = 200, arms = c("placebo", "active"),
  accrual_period = 6, follow_up = 18,
  event_dist = "weibull", event_shape = 1.5,
  hazard_control = 0.04, hazard_treatment = 0.03,
  dropout_rate = 0.01
)
table(trial$treatment, trial$status)
head(trial)
```

## Time and event model

| Input or output | Interpretation |
| --- | --- |
| `accrual_period` | Subjects enter between time 0 and this duration. The enrollment fraction follows Beta(`enroll_shape`, 1); shape 1 is uniform, smaller shapes favor early entry, larger shapes favor late entry. Zero places all subjects at time 0. |
| `follow_up` | Calendar time since accrual began when the entire study ends. It must exceed `accrual_period`. |
| `time` | Duration observed **since enrollment**, up to the first event, dropout, or study end. Calendar exit time is `enroll_time + time`. |
| `status` and `dropout` | Binary indicators: event (1, 0), dropout (0, 1), or administrative censoring (0, 0). |
| `dropout_rate` | Constant exponential dropout hazard per unit time since enrollment, independent of event time and treatment. Zero disables dropout. |

For exponential event times, each arm's `hazard_*` value \(\lambda\) is a constant hazard and its survival function is \(S(t)=e^{-\lambda t}\). For Weibull event times, `event_shape` is \(k>0\), the survival function is \(S(t)=e^{-\lambda t^k}\), and the **instantaneous** hazard is \(k\lambda t^{k-1}\). Thus \(\lambda\) is a *cumulative hazard coefficient* when \(k\ne1\); it is not a constant hazard. A Weibull shape of 1 recovers the exponential distribution. Zero event parameter means no events in that arm. Use one time unit throughout: when \(k\ne1\), \(\lambda\) has units of inverse time to the power \(k\). R's [Weibull reference](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/Weibull.html) defines its shape and scale parameters; the simulator uses \(\mathrm{scale}=\lambda^{-1/k}\) for \(\lambda>0\).

## Scope

The helper generates independent event and dropout times with common event shape in both arms and fixed calendar end. It does not enforce balanced randomization, model covariates or competing events, calibrate sample size or power, or perform an analysis. Its output is synthetic; validate any analysis plan separately. See [limitations and validation](limitations.md).
