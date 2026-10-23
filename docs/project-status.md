# Project status

**21 October 2026 · version 0.1.63 · active development · not on CRAN**

The [repository roadmap](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/ROADMAP.md) is the detailed plan. Its issues define completion criteria. Closing an issue records work within that scope; it does not validate every exported method or qualify the package for clinical decisions.

| Phase | Closed work | Open work |
| --- | --- | --- |
| P0: scope and initial numerical evidence | [Export inventory #47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47), [claims audit #48](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/48), [core reference cases #49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49) | Individual methods in the [evidence inventory](method-inventory.md) still await review. |
| P1: method families and reliability | [Design contracts #50](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/50), [survival family #51](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/51), [resampling review #52](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/52), [optional backends #53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53), [check matrix #54](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/54), [simulated-data audit #55](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/55), [documentation reconciliation #56](documentation-reconciliation.md) | Individual methods in the [evidence inventory](method-inventory.md) still await independent review. |
| P2: API and release | [Support policy #57](api-support-policy.md) classifies all 115 exports, with migration guidance for historical names. The [reviewed source](release-candidate.md) passed its five-job matrix and full all-Suggests check, including lengthy examples; automated artifact verification now retains a JSON receipt. | [Candidate gate #58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) remains open: confirm mail receipt and final version/source, review its checks and every NOTE, and make the release decision. |
| P3: stronger method evidence | The scoped numerical-reference batches through [reporting/auditability #163–#165](evidence-batches.md#completed-batch-reporting-and-auditability-163165) are complete, as are the subsequent categorical-outcome and stratified-risk helpers recorded in the inventory. | Further gaps in the [inventory](method-inventory.md) need individual issues and review. |
| Covariate workflows | [#194](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/194) consolidated 18 functions and their resources. Later [fitted-imputation helpers](fitted-imputation.md) (#199) and [saved encoding](fitted-encoding.md) (#201) preserve training replacements and categorical coding alongside saved scaling. [Numeric LASSO fold imputation](lasso-imputation.md) (#203) refits replacements and standardization for held-out predictions. [Saved neighbor models](fitted-knn.md) (#205) reuse training donors and mixed-data scales; numeric screening now integrates these within each fold (#207). [Saved-result prediction](predict-lasso-imputed.md) (#209) restores imputation and predictor order automatically. [Categorical fold encoding](lasso-encoding.md) (#211) adds opt-in additive designs and saved-recipe prediction. [Mixed-model name repair and prediction](covariate-mixed-model.md) (#213) preserve native fits with saved original/backend mappings. [Simulation-based percentile checks](simulated-vpc.md) (#215) summarize supplied response replicates; [fitted random-intercept simulation](covariate-simulation.md) (#217) generates those replicates with fixed fitted parameters. [Diagnostics keyboard and text access](diagnostics-app.md) (#219) adds browser checks. [Weight-allometric nonlinear fitting](allometric-nonlinear.md) (#221) adds a fixed-exponent oral model; [explicit starts](allometric-nonlinear.md#explicit-starting-values) (#223) support sensitivity checks and retain initialization metadata. [Saved allometric prediction](allometric-nonlinear.md#predict-from-a-saved-fit) (#225) applies the original names, restores row order, and evaluates zero subject effects with explicit dose histories. [Allometric response simulation](allometric-simulation.md) (#227) adds fresh subject effects and residuals with fitted parameters held fixed and explicit observation-only plotting. | Other model simulators, broader nonlinear covariate specifications, and manual assistive-technology/usability testing remain follow-ups. |

## Current package inventory

- **115 namespace exports:** 109 functions and six illustrative data objects.
- **Support labels:** two stable, 100 experimental, 11 example-only, and two
  deprecation candidates that remain callable.
- **Seven datasets:** the six exported objects plus `pharmo_example`, loaded with
  `data("pharmo_example", package = "PharmaStatsR")`.
- **Six vignettes:** the original workflow and five covariate guides. See
  [installation](installation.md#worked-vignettes) to build them from GitHub.

The [BIC screening reference](bic-screening.md) (#229) checks the imported
univariate screener against independent residual sums of squares and parameter
penalties. Saturated models and non-finite BIC comparisons now fail clearly;
the API remains experimental and the export count is unchanged. The
[stepwise AIC reference](aic-screening.md) (#231) covers additions, removal,
whole-factor penalties and a local minimum, with guards on accepted models.
The [complete-case LASSO reference](lasso-screening.md) (#233) adds independent
orthogonal coefficient/CV targets and fixes literal `(Intercept)` selection.

The [diagnostic plot references](covariate-diagnostic-plots.md) (#235) check
subject predictions, raw/normalized residuals and binned percentiles. They also
prevent prediction-name collisions and reject mismatched output lengths.

The [scaling reference](scaling-reference.md) (#237) covers ordinary and extreme
numeric units, small differences at large offsets, saved-parameter reuse and
representability boundaries. Ordinary finite estimates are retained.

The [numeric imputation reference](imputation-reference.md) (#239) adds fixed
location and donor targets, shares the finite-mean fallback across preprocessing,
and checks that saved replacements remain independent of new batches.

The [one-table design reference](fitted-encoding.md#one-table-design-checks)
(#241) fixes indicator/contrast values, term metadata and linear predictions.
Expanded labels must be unique and observed coding finite; missing rows remain
supported. Saved encoding also checks unused declared levels. The API and
support classifications remain unchanged.

The [time-varying table reference](timevarying-covariates.md) (#243)
checks typed values, metadata-defined keys, ordering and structural missing
cells. Duplicate wide keys now fail consistently with the long-input rule;
round-trip limits and source-record reconciliation are documented.

## What the evidence means

- The [reference cases](core-reference-cases.md) fix expected values for six core inference helpers. They do not cover all methods or datasets.
- The [method inventory](method-inventory.md) gives every export a [support level](api-support-policy.md) and labels representative tests as numerical references, behavior comparisons, smoke checks, or backend guards. Statistical methods remain experimental or example-only pending independent review.
- The [validation matrix](development.md#package-checks) and routine PR checks exercise the package in named environments. Their success establishes software-check results for those commits, not study-specific statistical validity.
- [Limitations and validation](limitations.md) describes known method and workflow boundaries.

## Reviewed source and remaining release work

The [reviewed development baseline](release-candidate.md#reviewed-development-baseline-15-october-2026)
is merged commit `971a37aaf203fad523807c254db930ce588ccbcd`. The routine R checks,
documentation build/deployment, and all five matrix jobs passed. Inspection of
the all-Suggests artifact confirmed **0 errors, 0 warnings, and 1 New submission
note**. Ordinary examples, the full SAEM fit in the lengthy-example pass, tests,
vignettes, and manuals passed. The source hash and job links are recorded in the
release evidence. Subsequent receipts are tracked in #58.

The older 7 October candidate does not contain the consolidated package.
The documentation refresh also changes packaged README/NEWS content; final
candidate selection requires checks of its own merged source. Review its
NOTEs, maintainer contact, final version, comments, and tag decision
under [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58).
The [documentation reconciliation](documentation-reconciliation.md) separates
current coverage from historical audits. No CRAN submission date is set.
