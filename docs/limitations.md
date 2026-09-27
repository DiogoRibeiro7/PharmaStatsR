# Limitations and validation

PharmaStatsR is under development and not on CRAN. The included datasets are small simulations, not evidence about real treatments or patients. Do not use them for clinical decisions or include patient data in issues.

## What the checks actually do

| Helper | Implemented behavior | Limit |
| --- | --- | --- |
| `pharma_column_report()` / `pharma_validation_report()` | Check required column names and return an estimand label, row count, required names, and `columns_present = TRUE` after success. | The label is recorded, not assessed. The report does not establish ICH E9(R1) compliance, estimand quality, or data integrity. |
| `pharma_check_columns()` / `check_ich_columns()` | Check the presence of required column names. | Column presence says nothing about their meaning, completeness, or provenance. |
| `pharma_audit_log()` / `pharma_audit_verify()` | Writes and verifies an HMAC chained local CSV log using a caller supplied key and the optional `openssl` package. | The log has no access control, secure key storage, or validated audit system; protect the key and file yourself. |
| `pharma_rate_metrics()` | Computes an unadjusted risk difference with a Newcombe interval and an unadjusted risk ratio with a half-count adjusted log interval. See [event-rate comparisons](rates.md). | The ratio interval is approximate and can have poor coverage in small or extreme samples; zero-event ratio point estimates can be undefined or infinite. The function does not adjust for confounding or repeated outcomes. |

The `pharma_validation_report()` and `check_ich_columns()` names are kept for compatibility. New code can use `pharma_column_report()` and `pharma_check_columns()` to make the scope clear. Since the report previously returned a misleading `compliant = TRUE` field, callers that inspected `$compliant` must now inspect `$columns_present` for the **column-presence check only**.

The [ICH E9(R1) guideline](https://database.ich.org/sites/default/files/E9-R1_Step4_Guideline_2019_1203.pdf) describes an estimand through the treatment conditions, population, variable, handling of intercurrent events, and population-level summary. A few column names cannot establish those attributes. Names and historical descriptions in this package can imply broader regulatory coverage than the implementation provides. Examine the function source and independently verify calculations before using outputs for a study. See the [security policy](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/SECURITY.md) for private vulnerability reporting.

## Validation for a real analysis

Document the planned estimand, population, endpoint, intervention, handling of intercurrent events and missing data, and a suitable method. Compare results against independent software or analytic references and review them in the study context. A green CI check or a successful column-presence report does not replace that work.
