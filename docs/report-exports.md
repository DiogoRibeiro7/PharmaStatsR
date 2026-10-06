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

## Independent linear-model reference

The [report-table reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-report-table-reference.R)
use two groups with four observations each:

\[
A=(1,2,3,4),\qquad B=(3,5,7,9).
\]

Their means are \(\bar A=2.5\) and \(\bar B=6\), so under
\`response ~ treatment\` with A as the reference level the coefficients are

\[
\hat\beta_0=2.5,\qquad \hat\beta_B=3.5.
\]

The within-group sums of squares are 5 and 20. With six residual degrees of
freedom,

\[
\widehat{\sigma}^2=\frac{25}{6}.
\]

Therefore

\[
SE(\hat\beta_0)=\sqrt{\frac{25}{24}}=\frac{5}{\sqrt{24}},
\]

and, because the two group means are independent with four observations each,

\[
SE(\hat\beta_B)=
\sqrt{\frac{25}{6}\left(\frac14+\frac14\right)}
=
\frac{5}{\sqrt{12}}.
\]

The corresponding t statistics are \(\sqrt6\) for the intercept and
\(0.7\sqrt{12}\) for the treatment contrast, both with 6 residual degrees of
freedom. The expected two-sided p-values use only
\`2 * stats::pt(-abs(t), df = 6)\`.

Confidence limits are reconstructed independently as

\[
\hat\beta \pm t_{1-\alpha/2,6}SE(\hat\beta),
\]

and are checked at both 90% and 95% confidence levels. No expected table value
comes from \`broom::tidy()\` or from a second call to
\`pharma_report_table()\`.

When the optional exporters are installed, the Excel workbook is read back and
its five numerical columns are compared with the same independent targets. The
Word artifact is inspected for the expected headings and coefficient terms.
This verifies preservation of the selected table content across the supported
export paths; it does not validate presentation standards.

This fixed reference covers one ordinary two-group linear model. It does not
establish correctness for every \`broom\` tidier, robust/model-specific
confidence intervals, transformed coefficients, publication formatting, ICH
reporting, or study-specific interpretation.


## R help

Full arguments and return values: [`pharma_report_table()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_report_table.Rd). In an installed package, run `help("pharma_report_table", package = "PharmaStatsR")`.
