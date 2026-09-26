# Limitations and validation

PharmaStatsR is under development and not on CRAN. The included datasets are small simulations, not evidence about real treatments or patients. Do not use them for clinical decisions or include patient data in issues.

## What the checks actually do

| Helper | Implemented behavior | Limit |
| --- | --- | --- |
| `pharma_validation_report()` | Checks that named columns exist and returns a row count, the supplied estimand string, and `compliant = TRUE` after that check succeeds. | The `compliant` field does **not** establish ICH E9(R1) compliance, estimand quality, data integrity, or regulatory validation. |
| `check_ich_columns()` | Checks the presence of required columns. | Column presence says nothing about their meaning, completeness, or provenance. |
| `pharma_audit_log()` / `pharma_audit_verify()` | Writes and verifies an HMAC chained local CSV log using a caller supplied key and the optional `openssl` package. | The log has no access control, secure key storage, or validated audit system; protect the key and file yourself. |
| `pharma_rate_metrics()` | Computes risk difference and risk ratio with approximate Wald intervals. | Wald intervals can be unreliable for small samples or event probabilities near zero or one; some zero-event ratio intervals are unavailable. |

Names and historical descriptions in this package can imply broader regulatory coverage than the implementation provides. Examine the function source and independently verify calculations before using outputs for a study. See the [security policy](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/SECURITY.md) for private vulnerability reporting.

## Validation for a real analysis

Document the planned estimand, population, endpoint, intervention, handling of intercurrent events and missing data, and a suitable method. Compare results against independent software or analytic references and review them in the study context. A green CI check or the helper's `compliant` field does not replace that work.
