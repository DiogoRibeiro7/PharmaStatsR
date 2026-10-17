# Interactive diagnostics app

Install the optional `shiny` package (at least 1.6.0; use a current release for
keyboard tab navigation), then launch:

```r
library(PharmaStatsR)
run_diagnostics_app()
```

Upload a CSV containing `SubjectID`, `Time`, and `DV`, then choose **Fit model**.
The built-in fit uses `DV ~ Time` with a random subject intercept. Rows missing
any of those three values are excluded from the fit and prediction plots; other
columns do not select analysis rows. A new upload clears the previous model,
and an invalid upload clears both model and data. Correct the CSV and upload it
again to recover. The Data source text retains the loaded filename after the
native file control resets. Preloaded `model` and `data` should describe the same analysis.

## Keyboard and text access

Use Tab and Shift+Tab to move through the page. The first link skips to the
Diagnostics region. The visible native file control opens the file chooser
with Enter or Space; selecting a file returns to the app. Move through Time bins
and Fit model, then use Left/Right arrows within the diagnostic tabs with current
Shiny. Each tab contains a **View numerical data** disclosure; Enter or Space
opens it. The next Tab reaches a labelled scroll region, where arrow keys scroll
the table. Tables can also be navigated by a screen reader using their captions
and column headers.

The page declares English, has a main heading and named landmarks, and shows a
visible focus outline. Model status and bin-validation feedback use persistent
polite live regions; results do not deliberately move keyboard focus. Upload and
fit failures remain readable in Model status. Transport failures, including
Shiny's upload-size limit, remain visible in a separate File upload status live
region; an upload rejected before reaching the server does not replace data. Each image has an explicit short
description and a nearby numerical alternative. These follow the
[W3C complex-image guidance](https://www.w3.org/WAI/tutorials/images/complex/) and
[ARIA status semantics](https://www.w3.org/TR/wai-aria/#status).

## What the tables mean

| View | Numerical alternative |
| --- | --- |
| Observed vs Predicted | One row per complete analysis observation: row name, Time, observed DV and subject-specific fitted response. The plot's diagonal denotes equality. |
| Residuals | Time, residual and type (Raw or Normalized), with analysis row names repeated for the two panels. Normalized residuals follow the model's residual method. |
| Binned summary | Mean time within each time bin, observed 5th percentile, median and 95th percentile, and median fitted response. Values come from the same summary used by the plot. |

**Row** means the analysis data row name, not SubjectID. CSV uploads normally
produce sequential row names; preloaded data can retain custom row names. Tables
show six significant digits and include all plotted observations or bin summaries,
without pagination or truncation. Empty time bins can contain missing summaries.
Changing Time bins updates the binned plot and table without refitting. An invalid
bin count clears those outputs until corrected. Uploading replacement data clears
all old diagnostic outputs until a new fit is available.

The binned ribbon describes observed percentiles; it is **not** simulated
predictive uncertainty. For model-based response replication, use the separate
[fitted-model simulation](covariate-simulation.md) and
[simulation-based percentile check](simulated-vpc.md) APIs.

## Evidence and limits

[Server tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-shiny-server.R)
compare displayed values with plotted values and backend residuals, retain
analysis row names after missing-row exclusion, check text escaping, and verify
invalidation and recovery. The
[browser suite](https://github.com/DiogoRibeiro7/PharmaStatsR/tree/main/scripts/browser)
uses Playwright and axe-core on a real local Shiny session. It checks keyboard
file selection, fitting, tab navigation, disclosures, scrolling, focus retention,
invalid and oversized uploads, failed fits, bin validation, recovery, and a 320-pixel viewport.
The CI job retains full axe results, screenshots and failure traces.

These are automated Chromium checks on a small synthetic fixture. They do not
establish WCAG conformance or cover screen-reader announcements, other browser
engines, operating-system file dialogs, or large-data performance. The browser
runner intercepts the native file chooser to select its fixture. Manual testing
with assistive technologies and representative users remains necessary; other
package dashboards are outside this suite. See [development](development.md#diagnostics-browser-checks)
for reproducible commands.
