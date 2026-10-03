# Landmark Cox analysis

`pharma_landmark_analysis()` fits an ordinary Cox model among subjects whose recorded follow-up extends **strictly beyond** a prespecified landmark. It subtracts the landmark from their observed follow-up times and retains their event indicators. An event or censoring at the landmark does not enter the risk set.

```r
library(PharmaStatsR)

fit <- pharma_landmark_analysis(
  survival::Surv(time, status) ~ treatment,
  data = pharma_survival,
  landmark = 5
)
summary(fit)
```

The response must be right-censored `Surv(time, status)` with a complete time and status for every row considered. `subset` accepts a logical expression in the original data or a complete logical vector with one value per row. It selects rows **before** the landmark risk set is formed. Covariates must be complete among the remaining subjects; missing covariates in excluded subjects do not prevent fitting.

## Direct reference

The following constructs the same risk set and time origin explicitly. Comparing coefficients and log likelihoods is a useful check when adapting the example to a study design.

```r
selected <- pharma_survival[
  pharma_survival$time > 5,
  , drop = FALSE
]
selected$time <- selected$time - 5
reference <- survival::coxph(
  survival::Surv(time, status) ~ treatment,
  data = selected
)
all.equal(unname(stats::coef(fit)), unname(stats::coef(reference)))
```

The fitted hazard ratio compares subjects **conditional on being event-free and observed beyond time 5**. It does not describe events before that time or remove selection bias from a time-dependent exposure. Choose the landmark before looking at outcomes, check the event coding and censoring assumptions, and consider a counting-process model for covariates that change during follow-up. See [Kaplan–Meier and log-rank](kaplan-meier.md) for unadjusted right-censored summaries and [limitations and validation](limitations.md) for the package's general scope.
