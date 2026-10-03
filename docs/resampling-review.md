# Resampling and simulation review

The five helpers use different sampling units and return different kinds of results. Choose a method from the analysis design, and set a seed immediately before a call if its random draws must be repeated. These checks establish software behavior on the linked fixtures; they do not establish coverage or power for a study.

| Helper | Random unit or process | Analysis rows and output | Interpretation |
| --- | --- | --- | --- |
| [`pharma_wild_bootstrap()`](wild-bootstrap.md) | Independent residual signs at fixed model rows and design. | Rejects missing model values; returns an `R` by coefficient matrix. | Raw, unstudentized coefficient draws, without an interval or test. |
| [`pharma_block_bootstrap()`](cluster-bootstrap.md) | Whole observed clusters sampled with replacement. | Keeps all rows in each selected copy; returns a list of `R` callback values, including `NULL`. | Raw callback draws; use `resample_id` when repeated copies need separate IDs. |
| [`pharma_parallel_bootstrap()`](parallel-bootstrap.md) | Independent rows sampled with replacement on future workers. | Always samples the input row count; returns a list of `R` callback values. | Raw callback draws, without automatic inference. |
| [`pharma_perm_f_test()`](permutation.md) | Evaluated response shuffled across selected, complete model rows. | Keeps the model matrix fixed; returns observed F, `R` permuted F values, and a Monte Carlo p-value. | A calibrated *global* test only when unrestricted response exchangeability is justified. |
| [`pharma_trial_simulate()`](trial-simulation.md) | Independent arm assignment, enrollment, event and dropout times. | Returns subject records with event, dropout, or administrative censoring. | Synthetic observations, not power estimates or an analysis. |

## Random-number behavior

`set.seed()` reproduces a call with the same inputs and R random-number settings. The wild, cluster, permutation, and trial helpers use the caller's R random stream. The row helper asks `future.apply` for reproducible streams per replicate, including random work done inside a callback; with the same seed, its sequential and multisession plans return the same draws. Neither seed control nor a large replicate count repairs a resampling unit that conflicts with the study design.

## Evidence and limits

The [wild-bootstrap tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-wild-bootstrap.R) check transformed terms, offsets, missingness, coefficient shape, and seeded draws. The [cluster tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-block-bootstrap.R) compare selected cluster copies with a seeded independent selection, including unequal sizes and a `NULL` callback. The [row tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-parallel-bootstrap-rng.R) compare future plans with random callback work. The [permutation tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-perm-f-test.R) compare observed and shuffled F values with direct linear fits after row selection and transformation. The [trial tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-trial-simulate.R) compare event and dropout proportions with the exponential competing-time probabilities and check Weibull survival.

For repeated participants, clustered observations, time order, unequal errors, or study-specific censoring, review the individual guide and [limitations](limitations.md) before using a returned statistic as evidence. The tests cover named fixtures and boundaries; they do not measure interval coverage, type I error across study scenarios, or clinical operating characteristics.
