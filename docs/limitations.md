# Limitations and validation

PharmaStatsR is under development and not on CRAN. The included datasets are small simulations, not evidence about real treatments or patients. Do not use them for clinical decisions or include patient data in issues.

## What the checks actually do

| Helper | Implemented behavior | Limit |
| --- | --- | --- |
| `pharma_column_report()` / `pharma_validation_report()` | Check required column names and return an estimand label, row count, required names, and `columns_present = TRUE` after success. | The label is recorded, not assessed. The report does not establish ICH E9(R1) compliance, estimand quality, or data integrity. |
| `pharma_check_columns()` / `check_ich_columns()` | Check the presence of required column names. | Column presence says nothing about their meaning, completeness, or provenance. |
| `pharma_audit_log()` / `pharma_audit_verify()` | Writes and verifies an HMAC chained local CSV log using a caller supplied key and the optional `openssl` package. | The log has no access control, secure key storage, or validated audit system; protect the key and file yourself. |
| `pharma_perm_f_test()` | Compares the full linear model with an intercept-only or zero-mean model using unrestricted response permutations; see [global permutation F-test](permutation.md). | Requires exchangeable observations under the global null; it does not test individual terms while adjusting for other predictors. |
| `pharma_parallel_bootstrap()` | Resamples independent rows with replacement, using reproducible future RNG streams; see [row bootstrap](parallel-bootstrap.md). | Does not preserve clustered, repeated, or time-ordered dependence; returns statistics, not calibrated inference. |
| `pharma_block_bootstrap()` | Resamples whole observed clusters with replacement and calls a supplied statistic; see [cluster bootstrap](cluster-bootstrap.md). | The statistic must suit the sampling design. Repeated source clusters need distinct `resample_id` values for grouped downstream fits; the helper does not return calibrated inference. |
| `pharma_wild_bootstrap()` | Returns fixed-design linear-model coefficient draws using independent Rademacher signs on unscaled residuals; see [wild bootstrap](wild-bootstrap.md). | Does not test a null or return calibrated intervals; observation-level signs do not account for clustered or repeated observations, and high leverage can affect accuracy. |
| `pharma_competing_risks()` | Fits a Fine–Gray subdistribution hazards model from numeric event codes and a model matrix; see [competing risks](competing-risks.md). | Estimates the subdistribution hazard for one selected cause under the model and censoring assumptions; it does not estimate a cause-specific hazard or address missing model values. |
| `pharma_trial_simulate()` | Generates two-arm event, dropout, and administrative censoring times; see [trial simulation](trial-simulation.md). | Random assignment does not guarantee balance; event and dropout draws are independent, and simulated data do not establish operating characteristics or clinical validity. |
| `pharma_bayes_stopping()` | Computes a beta-binomial posterior probability that one response rate exceeds a fixed benchmark and checks it against a cutoff. See [single-arm posterior threshold](bayesian-threshold.md). | It does not compare arms or calibrate an interim stopping rule's operating characteristics. |
| `pharma_sample_reestimate()` | Calculates a balanced two-arm normal-approximation planning total from a mean difference and within-arm variance; see [sample size planning](sample-size.md). | It does not compute interim conditional power or control the error rate of a data-dependent sample-size change. |
| `pharma_rate_metrics()` | Computes an unadjusted risk difference with a Newcombe interval and an unadjusted risk ratio with a half-count adjusted log interval. See [event-rate comparisons](rates.md). | The ratio interval is approximate and can have poor coverage in small or extreme samples; zero-event ratio point estimates can be undefined or infinite. The function does not adjust for confounding or repeated outcomes. |

The `pharma_validation_report()` and `check_ich_columns()` names are kept for compatibility. New code can use `pharma_column_report()` and `pharma_check_columns()` to make the scope clear. Since the report previously returned a misleading `compliant = TRUE` field, callers that inspected `$compliant` must now inspect `$columns_present` for the **column-presence check only**.

The [ICH E9(R1) guideline](https://database.ich.org/sites/default/files/E9-R1_Step4_Guideline_2019_1203.pdf) describes an estimand through the treatment conditions, population, variable, handling of intercurrent events, and population-level summary. A few column names cannot establish those attributes. Names and historical descriptions in this package can imply broader regulatory coverage than the implementation provides. Examine the function source and independently verify calculations before using outputs for a study. See the [security policy](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/SECURITY.md) for private vulnerability reporting.

## Validation for a real analysis

Document the planned estimand, population, endpoint, intervention, handling of intercurrent events and missing data, and a suitable method. Compare results against independent software or analytic references and review them in the study context. A green CI check or a successful column-presence report does not replace that work.
