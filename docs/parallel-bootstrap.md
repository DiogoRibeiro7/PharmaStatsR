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

For parallel work, pass `plan = "multisession"` (the default). This built-in strategy configures two workers; caller-supplied strategies other than `"multisession"` keep their own worker settings. `future` and `future.apply` are optional dependencies and must be installed to call this helper. The previous future plan is restored after the function returns, including on an error.

## Sampling and random seeds

| Property | Behavior |
| --- | --- |
| Sampling unit | An individual input row. Each draw samples rows independently with replacement. |
| Replicate size | Always the original row count. Repeated rows and omitted rows are normal. |
| Result | A list of `R` values returned by your `statistic`. |
| RNG | `future.seed = TRUE` provides a separate, reproducible stream per replicate. With the same `set.seed()` value, results match across sequential and parallel plans. |

The data frame passed to your statistic uses base R's `data.frame` class. Missing values are passed through; the statistic decides how to handle them. `R` must be a positive whole number. `plan` must be a strategy name, function, or call accepted by `future::plan()`.

## Independent finite-support reference

The self-contained [reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-row-bootstrap-reference.R) use three synthetic observations with fixed identities and values:

| Row | ID | Value |
| --- | --- | --- |
| row-A | 1 | 0 |
| row-B | 2 | 2 |
| row-C | 3 | 7 |

Each bootstrap sample contains three independent draws from these three rows. There are exactly `3^3 = 27` equally likely ordered samples. If `b` and `c` are the numbers of copies of IDs 2 and 3, respectively, its mean is `(2*b + 7*c)/3`. Expected values use this fixed count formula, not the callback evaluated on a backend resample.

### Distribution and exact moments

The table groups ordered samples with the same sum. Multiplicities are retained: the ten distinct means are not equally likely.

| Sample sum | Sample mean | Multiplicity out of 27 |
| --- | --- | --- |
| 0 | 0 | 1 |
| 2 | 2/3 | 3 |
| 4 | 4/3 | 3 |
| 6 | 2 | 1 |
| 7 | 7/3 | 3 |
| 9 | 3 | 6 |
| 11 | 11/3 | 3 |
| 14 | 14/3 | 3 |
| 16 | 16/3 | 3 |
| 21 | 7 | 1 |

For one draw from the empirical distribution, the mean is 3 and the variance is `((0-3)^2 + (2-3)^2 + (7-3)^2)/3 = 26/3`. The mean of three independent draws therefore has

\[
\operatorname{E}_*(\overline{Y}^*)=3,\qquad
\operatorname{Var}_*(\overline{Y}^*)=\frac{26}{9},\qquad
\operatorname{E}_*((\overline{Y}^*)^2)=\frac{107}{9}.
\]

The star denotes conditioning on the three observed values. Full-support calculations divide by 27, not the sample-variance divisor 26. The arithmetic-only test checks the entire table, all 27 distinct index sequences, the mean, second moment, and variance. It runs even when neither future package is installed.

A standalone base-R calculation reproduces the reference without a bootstrap backend:

```r
indices <- as.matrix(expand.grid(a = 1:3, b = 1:3, c = 1:3))
sums <- apply(indices, 1L, function(ids) {
  2 * sum(ids == 2L) + 7 * sum(ids == 3L)
})
means <- sums / 3
table(sums)
c(
  mean = mean(means),
  second_moment = mean(means^2),
  variance = sum((means - 3)^2) / 27
)
```

Exact Python `fractions.Fraction` enumeration and a separate NumPy calculation using explicitly indexed row arrays agree with these targets within absolute tolerance `1e-12`. Neither supplies an expected value by running the production R callback. This is a deterministic distributional identity, not a Monte Carlo coverage experiment.

### Seeded execution and independence of the reference

A sequential loop using the caller's ordinary seed does not reproduce the separate per-replicate streams used by `future.seed = TRUE`. The execution reference therefore first captures each worker's starting `.Random.seed` using the public `future.apply::future_lapply()` interface. It then assigns those captured seeds in base R, replays only `sample.int(3L, 3L, replace = TRUE)`, and calculates each expected mean from the fixed counts above. No backend resampled data or callback result supplies an expected statistic.

This deliberately separates the claims: **the mean distribution and numerical arithmetic are independent; the stream-allocation comparison is a backend contract check**, not an independent validation of future's random-number generator. The [official RNG documentation](https://future.apply.futureverse.org/reference/future_lapply.html#reproducible-random-number-generation-rng) describes pregenerated per-iteration streams, seed capture, reproducibility across strategies, and the caller-state update.

Sequential tests use seeds 11 and 150 and one and 31 replicates. The bounded multisession tests use seed 150, one and 31 replicates, and `future::tweak(future::multisession, workers = 2L)`. Both compare numerical results, sampled IDs, replicate ordering, fixed row counts, base-data-frame inputs, and the post-call caller RNG state against the same reference. Single-replicate calls must match the first result of the longer call. Original input data remain unchanged. The helper still samples random replicates; it does not enumerate the support when `R >= 27`.

### Callback policies and cleanup

Positive and negative affine responses, `7 + b*value` with `b = 2` and `b = -2`, change the expected means by the same affine expression without changing sampled identities. A multisession test also forwards `shift = 7` and `multiplier = -2` into the callback. An unrelated all-missing column must reach the callback unchanged.

When ID 2's value is missing, its row remains eligible for sampling. With the default `mean()` policy, any sample containing that row returns `NA`. With `na.rm = TRUE`, the expected mean is `7*c/(3-b)`. If all three sampled values are missing, the callback returns `NaN` after removing them; that does not mean that the bootstrap removed rows. A separate all-missing input makes this boundary deterministic rather than relying on a particular random sample. Every callback still receives three rows.

Tests require restoration of the caller's future plan after successful calls and callback failures in both sequential and multisession execution. Test cleanup also restores the previous plan if an assertion interrupts a test. The test-only seed helper restores both RNG kinds and the original `.Random.seed`, including its absence, on normal and error exits. **Production calls continue to advance the caller's random-number stream**; seed isolation belongs to the tests, not a changed public behavior.

Numerical assertions use `testthat::expect_equal()` with tolerance `1e-12`; support multiplicities, sampled identities and RNG state have exact comparisons. There are no probabilistic requirements that a small random sample's moments approximate the exact moments. Execution tests explicitly guard `future` and `future.apply` and use the existing installed-backend checks. The existing [parallel RNG and plan tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-parallel-bootstrap-rng.R) and optional-backend guards remain unchanged.

### Contrast with whole-cluster resampling

This fixture has a fixed denominator of three observations in every replicate. The [unequal-cluster reference](cluster-bootstrap.md#independent-unequal-cluster-reference) samples whole clusters with sizes 1, 2, and 3, so the pooled-row denominator can change. Its pooled-row mean and equally weighted cluster-copy mean are different statistics. Treating dependent observations as individual rows does not become valid merely because this row-bootstrap calculation passes.

## Scope

This is an **independent-row bootstrap**. It does not preserve subjects, clusters, time-series dependence, or treatment-stratified allocation. Use [cluster bootstrap](cluster-bootstrap.md) when the independent sampled units are clusters. Returned statistics are not automatically confidence intervals or hypothesis tests; their validity depends on the statistic, sampling assumptions, and any interval or test procedure you choose. See [limitations and validation](limitations.md).

The [future.apply RNG reference](https://future.apply.futureverse.org/reference/future_lapply.html#reproducible-random-number-generation-rng) describes backend-independent random streams.

The finite-support reference verifies conditional arithmetic for these three values and the stated callback variants. It does not establish adequate inference with three observations, interval coverage, dependent-data validity, arbitrary callback behavior, or parallel scalability. Statistical support remains experimental. No estimator, public signature, dependency, workflow, or package version changes are introduced by this reference.

## R help

Full arguments and return values: [`pharma_parallel_bootstrap()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_parallel_bootstrap.Rd). In an installed package, run `help("pharma_parallel_bootstrap", package = "PharmaStatsR")`.
