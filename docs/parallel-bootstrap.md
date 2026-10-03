# Row bootstrap with future workers

`pharma_parallel_bootstrap()` draws individual data-frame rows with replacement and evaluates your statistic once per replicate. Every replicate contains the original number of rows. It uses `future.apply`, so the selected future plan controls whether those replicates run sequentially or on separate workers.

```r
library(PharmaStatsR)

set.seed(42)
draws <- pharma_parallel_bootstrap(
  pharma_sample,
  statistic = function(d) mean(d$response),
  R = 500,
  plan = "sequential"
)
unlist(draws)
```

For parallel work, pass `plan = "multisession"` (the default). `future` and `future.apply` are optional dependencies and must be installed to call this helper. The previous future plan is restored after the function returns, including on an error.

## Sampling and random seeds

| Property | Behavior |
| --- | --- |
| Sampling unit | An individual input row. Each draw samples rows independently with replacement. |
| Replicate size | Always the original row count. Repeated rows and omitted rows are normal. |
| Result | A list of `R` values returned by your `statistic`. |
| RNG | `future.seed = TRUE` provides a separate, reproducible stream per replicate. With the same `set.seed()` value, results match across sequential and parallel plans. |

The data frame passed to your statistic uses base R's `data.frame` class. Missing values are passed through; the statistic decides how to handle them. `R` must be a positive whole number. `plan` must be a strategy name, function, or call accepted by `future::plan()`.

## Scope

This is an **independent-row bootstrap**. It does not preserve subjects, clusters, time-series dependence, or treatment-stratified allocation. Use [cluster bootstrap](cluster-bootstrap.md) when the independent sampled units are clusters. Returned statistics are not automatically confidence intervals or hypothesis tests; their validity depends on the statistic, sampling assumptions, and any interval or test procedure you choose. See [limitations and validation](limitations.md).

The [future.apply RNG reference](https://future.apply.futureverse.org/reference/future_lapply.html#reproducible-random-number-generation-rng) describes backend-independent random streams.

## R help

Full arguments and return values: [`pharma_parallel_bootstrap()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_parallel_bootstrap.Rd). In an installed package, run `help("pharma_parallel_bootstrap", package = "PharmaStatsR")`.
