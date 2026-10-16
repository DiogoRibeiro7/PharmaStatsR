# Simulation-based percentile diagnostics

`plot_simulated_vpc()` compares observed response percentiles with the same
percentiles calculated in replicated datasets. Each column of `simulations`
contains one complete response replicate, in the exact row order of `data`.
The function returns a faceted ggplot, an inspectable summary table in
`plot$data`, and attributes recording the binning choices and row membership.
It is experimental and does not fit a model or generate simulations internally.

The existing `plot_vpc()` continues to compare observed percentiles with fitted
medians, without simulation. App and report plots continue to use that
existing descriptive workflow.

## Generate responses under an explicit model

This runnable example uses a known Gaussian random-intercept process. For each
replicate, draw one fresh subject effect per subject and one independent residual
per observation. Reuse the observation schedule and subject indices so rows
within the same subject share their random effect. These are illustrative model
parameters, not estimates from the observed data.

```r
library(PharmaStatsR)
set.seed(215)
observed <- data.frame(
  SubjectID = rep(seq_len(20), each = 4),
  Time = rep(0:3, times = 20)
)
replicate_response <- function() {
  subject_effect <- rnorm(20, sd = 0.7)
  2 + 0.5 * observed$Time + subject_effect[observed$SubjectID] +
    rnorm(nrow(observed), sd = 0.3)
}
observed$DV <- replicate_response()
simulations <- replicate(500, replicate_response())
rownames(simulations) <- rownames(observed)
check <- plot_simulated_vpc(observed, simulations, bins = 4)
check
check$data
attr(check, "vpc_bins")
attr(check, "vpc_settings")
```

For an estimated model, generate complete replicated responses using a simulator
appropriate to that model, including residual variability and the intended
random effects or correlation. A matrix of fitted means alone does not reproduce
that variability. Specify whether predictions concern new subjects or existing
subjects and whether parameters are fixed or resampled. Parameter uncertainty
appears in the plot only when it was included in the supplied simulations.
Model-specific simulation adapters are outside this helper's scope.

## Calculation and interpretation

1. Compute type-7 quantile edges from the observed time column for the requested
   `bins`. Collapse duplicate edges. Bins are right-closed and include the lowest
   endpoint; omit empty bins. Constant time produces one bin. Plot each bin at
   the mean of its observed times.
2. Within each nonempty bin, calculate the observed response quantile for each
   entry of `probs`, default `c(0.05, 0.5, 0.95)`.
3. Calculate those quantiles separately within every replicate, retaining the
   same rows and bins. Do not pool responses from different replicates.
4. Across the replicate quantile statistics, take their median and the
   `(1 - level) / 2` and `(1 + level) / 2` quantiles. All quantiles use type 7.
   The default `level = 0.9` produces central 90% simulation intervals.

Each facet identifies a response probability. Solid lines and filled points
show observed percentiles; dashed lines and open points show the median
simulated percentile. Blue ribbons and vertical ranges show the simulation
intervals. Points and ranges remain visible for a single bin.

This construction follows the replicate-wise percentile principle described by
[Bergstrand et al. (2011)](https://pmc.ncbi.nlm.nih.gov/articles/PMC3085712/).
This implementation does **not** implement that paper's prediction correction.
The bands describe variation of a percentile statistic under the supplied
simulation design. They are not individual-response intervals, simultaneous
coverage bands, parameter confidence intervals, or a formal goodness-of-fit
test. No p-value or automatic model acceptance decision is returned.

Observations receive equal weight within a bin; subjects with more observations
in a bin contribute more rows. Replicates receive equal weight when summarizing
their quantiles. The bin choice, sample size, and simulated process all affect
the comparison. Two replicates are permitted for deterministic checks, but
use enough simulations for the intended tail probabilities and assess Monte
Carlo stability. Sparse bins and a small number of replicates give unstable
percentile estimates.

## Inspect and verify the summary

The following small deterministic matrix makes both quantile steps transparent.
It is a numerical reference, not a model simulation example.

```r
reference <- data.frame(Time = 0:3, DV = c(0, 4, 10, 18))
replicates <- matrix(c(
  0, 4, 10, 18, 2, 6, 14, 22, 4, 8, 18, 26,
  6, 10, 22, 30, 8, 12, 26, 34
), nrow = 4)
result <- plot_simulated_vpc(
  reference, replicates, bins = 2,
  probs = c(0.25, 0.5, 0.75), level = 0.5
)
result$data[c("bin", "probability", "observed", "simulated", "lower", "upper")]
stopifnot(
  identical(result$data$observed, c(1, 2, 3, 12, 14, 16)),
  identical(result$data$simulated, c(5, 6, 7, 20, 22, 24)),
  identical(result$data$lower, c(3, 4, 5, 16, 18, 20)),
  identical(result$data$upper, c(7, 8, 9, 24, 26, 28))
)
```

The bin edges are `0, 1.5, 3`. In the first bin, the observed quartiles are
`1, 2, 3`. Replicate shifts are `0, 2, 4, 6, 8`, so the replicate-wise median
quartiles are `5, 6, 7`; the central 50% endpoints add 2 and 6 to the observed
quartiles. Pooling all ten simulated responses instead gives quartiles `4, 6, 8`,
which is a different calculation. The second bin uses shifts `0, 4, 8, 12, 16`.
The [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-simulated-vpc.R)
also verify plotted coordinates, alignment, ties, constant-time cohorts,
permutation and affine transformations, and random-stream preservation.

`result$data` has one row per nonempty bin and probability. It includes bin
edges (`left`, `right`), `bin_time`, observed count `n`, `probability`, `observed`,
`simulated`, `lower`, `upper`, and replicate count `nsim`. The `vpc_bins` attribute
maps original row names to bin numbers. Bin numbers index the collapsed breaks
and can have gaps where intervals are empty. `vpc_settings` records those
breaks, probabilities, coverage, replicate count, and quantile type.

## Input boundaries

- Use finite, real numeric time/response columns and a finite numeric matrix
  with at least two replicate columns. No missing values, dropped rows,
  imputation, or partial replicate summaries are allowed.
- Alignment is positional. When the matrix has row names, they must match
  `rownames(data)` exactly and in order. Names are checked, never reordered.
  An unnamed matrix cannot detect a permutation mistake: align it explicitly.
- Literal time and response names are supported via `time` and `response`.
  `probs` must be strictly increasing and lie strictly between 0 and 1.
- Select the same observation cohort in both data and simulations before
  calling. This helper does not handle censoring, dose/event records,
  prediction correction, weighting, or stratification. Separate subgroup
  calls require a justified comparison design.
- The function consumes no random numbers. Set and record the seed in the
  simulation step, along with the generating model, parameters, and design.
