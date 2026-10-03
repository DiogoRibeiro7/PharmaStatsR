# API support and lifecycle

PharmaStatsR is in active development at version 0.1.62. The [export inventory](method-inventory.md) assigns one support level to each of the 72 entries in `NAMESPACE`: two stable, 58 experimental, ten example-only, and two deprecation candidates. These labels describe the package's **software API commitment**. They do not validate a statistical method for a particular study or establish regulatory compliance. Read the individual help and [limitations](limitations.md) before using a method.

| Level | What to expect |
| --- | --- |
| **Stable** | We intend to preserve the documented arguments, return structure, and stated behavior across ordinary updates. A necessary breaking change needs an issue, migration instructions, tests, and a release note before it ships. This is a compatibility promise for the narrow documented scope, not a clinical validation claim. |
| **Experimental** | The export works within its documented constraints and is tested to the extent recorded in the inventory. Its interface, defaults, or results may change after review. We document consequential changes and migration steps in `NEWS.md`; callers should pin a package version and verify outputs. |
| **Example-only** | The export supplies illustrative data, a greeting, a simulated dashboard, or a template. It is maintained as an example and carries no promise that its contents or layout suit production analysis. Changes to its public shape should still be documented. |
| **Deprecation candidate** | The export remains callable and is **not deprecated** today. We favor the named replacement for new work. Any actual deprecation requires a separate reviewed change with warnings, migration guidance, tests, and a release note; removal requires another review and a later release. |

## Decisions for the current API

- **Stable, limited column checks:** `pharma_check_columns()` checks only required names; `pharma_column_report()` records an estimand label, row count, and column-presence result. Neither checks values, analysis assumptions, or compliance. Their tests cover the documented input and return contracts. These are the only stable exports at present.
- **Experimental statistical methods:** all 43 method exports remain experimental, including the core helpers with fixed reference cases. The [inventory](method-inventory.md) distinguishes numerical references, backend comparisons, and smoke tests; none amounts to independent review of every supported design and use case.
- **Experimental optional bridges:** `pharma_ai_model_select()` selects among successful `caret` fits using the requested metric, warns about failed candidates, and needs the optional backend and model engines. It does not certify a model or guarantee a default candidate will fit. `pharma_scipy_ttest()` delegates to SciPy through `reticulate` and requires that Python environment; it does not silently substitute an R test. `pharma_report_table()` formats selected columns and optional files, without claiming a reporting standard. Their backend and output contracts can evolve.
- **Experimental local facilities:** `pharma_config()` and `with_pharma_config()` manage package options; currently only `log_level` is consumed by package code. The plugin and statistic registries hold callable functions in the package's process-local environments. They provide no persistence, isolation, or verification of registered methods. The audit helpers check a local keyed chain but cannot detect deletion of its tail. None is a validated workflow system.
- **Example-only:** the six bundled datasets, `pharma_greeting()`, `pharma_dashboard()`, `pharma_interim_dashboard()`, and `pharma_generate_sap()`. The dashboards use simulated data or enrollment; the SAP generator writes placeholders. They are not live study monitoring or an approved analysis plan.
- **Deprecation candidates:** `check_ich_columns()` and `pharma_validation_report()` are historical names that imply more than their column-presence checks do. Both continue to call their replacements. No warning or removal is proposed here.

## Migrate historical names

| Existing call | New code | Behavior to check |
| --- | --- | --- |
| `check_ich_columns(data)` | `pharma_check_columns(data, c("subject", "treatment", "dose"))` | Pass the old default column list explicitly. If the old call supplies `required`, pass the same vector. Both return `TRUE` or error on missing columns. |
| `pharma_validation_report(data, estimand)` | `pharma_column_report(data, estimand)` | Both currently use `c("subject", "treatment", "dose", "response")` by default and return `estimand`, `n`, `required_columns`, and `columns_present`. Pass any custom `required` vector unchanged. The historical `compliant` field was removed earlier and must not be inferred from this report. |

No export is renamed or removed by this policy. A caller can migrate at its own pace; existing names remain documented and callable. Before a candidate becomes deprecated, a separate PR must establish a warning that does not conceal the result, migration examples, tests for both paths, and a release note. Removal is a separate decision after users have had a documented transition period; no date is set.

## Changing a support level

New exports need an inventory row, a support label, R help, a site explanation, and tests for the intended contract. The PR check compares `NAMESPACE` with the inventory so no entry can be missed. Promoting a statistical method to stable requires a reviewed input and return contract, assumptions, independent numerical evidence for its stated scope, meaningful boundaries, and a migration plan for known discrepancies. A label change needs an issue and a `NEWS.md` entry. New feature work follows the P0/P1 correctness and reliability gates in the [roadmap](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/ROADMAP.md); the next release-candidate decision is [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58).
