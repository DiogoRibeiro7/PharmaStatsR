# Model estimate table exports

`pharma_report_table(model)` selects `term`, `estimate`, `conf.low`,
`conf.high`, and `p.value` from `broom::tidy(model, conf.int = TRUE)`. The
model's tidy output must contain all five columns. Without a `file` argument,
the function returns a data frame and needs no optional export packages.

```r
fit <- lm(response ~ treatment, data = pharma_sample)
estimates <- pharma_report_table(fit)
```

Use `file` to write the same table to Excel or Word:

| Extension | Optional R packages | Example |
| --- | --- | --- |
| `.xlsx` | `openxlsx` | `pharma_report_table(fit, file = "estimates.xlsx")` |
| `.docx` | `flextable`, `officer` | `pharma_report_table(fit, file = "estimates.docx")` |

Install only the exporter you need with `install.packages()`. Missing packages
are named in the error before a file is written. Both file modes return the
five-column data frame invisibly. The CI tests read the Excel workbook back
with `openxlsx::read.xlsx()` and inspect the Word table with
`officer::docx_summary()`.

This is an extraction of model output, not a validated analysis report or an
APA or ICH table. Check the model, population, confidence intervals, and
presentation against your analysis plan before using the file. See the
[reporting scope audit](claims-audit.md) and [limitations](limitations.md).

## R help

Full arguments and return values: [`pharma_report_table()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_report_table.Rd). In an installed package, run `help("pharma_report_table", package = "PharmaStatsR")`.
