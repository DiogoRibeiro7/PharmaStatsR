# Reporting and monitoring helper scope

Several historical function names refer to regulatory concepts. This page compares those names with the current implementation. It does not assess whether any function is suitable for a particular study. The [export inventory](method-inventory.md) records source, R help, and representative tests for every public symbol.

| Helper | Current return or side effect | What it does not establish |
| --- | --- | --- |
| `pharma_check_columns()` and historical `check_ich_columns()` | Return `TRUE` if every requested column name exists; otherwise error. | Column values, provenance, study design, or ICH compliance. The historical name remains for existing scripts; use `pharma_check_columns()` in new code. |
| `pharma_column_report()` and historical `pharma_validation_report()` | Return an estimand **label**, row count, requested columns, and `columns_present = TRUE` after the column check succeeds. | An assessed estimand, valid data, or a regulatory validation report. The former `compliant` field was removed; inspect `$columns_present` only for the column-name check. |
| `pharma_audit_log()` and `pharma_audit_verify()` | Append a local keyed HMAC-SHA256 CSV chain and verify records that remain in the file. | A complete or controlled audit trail. A valid prefix remains valid after deletion of its final rows. The caller must protect the key and log; there is no access control or concurrent-write protection. See [local audit log integrity](audit-log.md). |
| `pharma_report_table()` | Select five columns (`term`, `estimate`, `conf.low`, `conf.high`, `p.value`) from `broom::tidy()` and optionally write the table to Excel or Word. | An APA or ICH reporting standard, validated model, or complete clinical report. The model's tidy output must contain all five columns; optional export packages are required for files. |
| `pharma_generate_sap()` | Return Markdown placeholder sections or write them to a file; reject invalid section names and content before writing. | A completed, reviewed, or approved statistical analysis plan. The caller supplies study-specific content and independently reviews the output. |
| `pharma_dashboard()` | Return the bundled R Markdown path or open a Shiny view of simulated package datasets. | Live data ingestion, patient monitoring, or a trial decision. |
| `pharma_interim_dashboard()` | Return the bundled R Markdown path or open a Shiny chart of newly simulated enrollment counts. | Live enrollment tracking, interim statistics, a stopping boundary, or an independently calibrated monitoring rule. Each render may draw a different chart. |
| `pharma_bayes_stopping()` | Return a single-arm beta-binomial probability and a Boolean `stop` flag for crossing a supplied posterior cutoff. | A treatment comparison or calibrated repeated-look stopping design. The flag is a threshold check, not a recommendation to stop a trial. See [single-arm posterior threshold](bayesian-threshold.md). |
| `pharma_sample_reestimate()` and `pharma_group_seq()` | Return, respectively, a balanced two-arm normal-approximation planning total and planned group-sequential efficacy boundaries. | An interim adaptation decision, conditional power, or a complete monitoring plan. See [sample size planning](sample-size.md) and [group-sequential designs](sequential.md). |


### SAP template artifact contract

The [deterministic SAP artifact tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-sap-reference.R)
treat `pharma_generate_sap()` as a text generator, not as an analysis-plan
validator. A fixed reference spells out the entire expected Markdown vector
rather than rebuilding it with the helper's section loop.

The fixture deliberately includes reordered default sections, two custom
sections, an empty section body, UTF-8 text, and Markdown-sensitive literal
characters such as backticks, brackets, pipes, hashes, and asterisks. The exact
section order is:

1. Software
2. Endpoints
3. Objectives
4. Decision Rules
5. Notas UTF-8

The in-memory character vector must match the explicit reference exactly. When
a path is supplied, reading the Markdown back as UTF-8 must produce the same
line vector. A raw-file check normalizes only platform newline conventions
(CRLF versus LF) before comparing the complete UTF-8 text, including the final
newline written by `writeLines()`.

The reference also covers a custom-only template with
`include_sections = NULL`, preserves empty author and section strings exactly,
and verifies that a valid call replaces an existing file with the complete new
artifact.

Validation still happens before writing. For invalid default section names,
duplicate sections, invalid custom-section names, missing scalar text, or
non-scalar content, an existing output file must remain byte-for-byte
unchanged. This is a file-integrity contract for validation failures, not a
transactional or concurrent-write guarantee.

These checks establish deterministic template serialization only. They do not
assess whether the objectives, endpoints, populations, methods, multiplicity
strategy, missing-data strategy, interim rules, software specifications, or
other sections form a scientifically complete or regulatorily acceptable SAP.
They also do not provide version control, electronic signatures, review or
approval workflow, PDF/Word rendering, or protocol consistency checks.


The dashboard files and SAP text are **demonstrations**. They contain no study data source or approval workflow. The reporting table is an extraction of model output; check the model, population, uncertainty, and presentation against a prespecified analysis before using it in a real report. For project-wide constraints, see [limitations and validation](limitations.md).

Historical names are retained for compatibility. The clearer column helpers already provide a migration path. The SAP template now rejects unknown, blank, or duplicate default section names, and requires scalar text and uniquely named custom sections. Calls that relied on silent omissions must correct their inputs; see `NEWS.md` for migration details.
