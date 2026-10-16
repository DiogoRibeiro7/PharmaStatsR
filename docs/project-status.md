# Project status

**16 October 2026 · version 0.1.63 · active development · not on CRAN**

The [repository roadmap](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/ROADMAP.md) is the detailed plan. Its issues define completion criteria. Closing an issue records work within that scope; it does not validate every exported method or qualify the package for clinical decisions.

| Phase | Closed work | Open work |
| --- | --- | --- |
| P0: scope and initial numerical evidence | [Export inventory #47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47), [claims audit #48](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/48), [core reference cases #49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49) | Individual methods in the [evidence inventory](method-inventory.md) still await review. |
| P1: method families and reliability | [Design contracts #50](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/50), [survival family #51](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/51), [resampling review #52](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/52), [optional backends #53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53), [check matrix #54](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/54), [simulated-data audit #55](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/55), [documentation reconciliation #56](documentation-reconciliation.md) | Individual methods in the [evidence inventory](method-inventory.md) still await independent review. |
| P2: API and release | [Support policy #57](api-support-policy.md) classifies all 106 exports, with migration guidance for historical names. The [reviewed source](release-candidate.md) passed its five-job matrix and full all-Suggests check, including lengthy examples; automated artifact verification now retains a JSON receipt. | [Candidate gate #58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) remains open: confirm mail receipt and final version/source, review its checks and every NOTE, and make the release decision. |
| P3: stronger method evidence | The scoped numerical-reference batches through [reporting/auditability #163–#165](evidence-batches.md#completed-batch-reporting-and-auditability-163165) are complete, as are the subsequent categorical-outcome and stratified-risk helpers recorded in the inventory. | Further gaps in the [inventory](method-inventory.md) need individual issues and review. |
| Covariate workflows | [#194](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/194) consolidated 18 functions and their resources. Later [fitted-imputation helpers](fitted-imputation.md) (#199) and [saved encoding](fitted-encoding.md) (#201) preserve training replacements and categorical coding alongside saved scaling. [Numeric LASSO fold imputation](lasso-imputation.md) (#203) refits replacements and standardization for held-out predictions. | Categorical preprocessing within folds, saved neighbor models, nonlinear covariates, predictive simulation, and browser checks remain follow-ups. |

## Current package inventory

- **106 namespace exports:** 100 functions and six illustrative data objects.
- **Support labels:** two stable, 91 experimental, 11 example-only, and two
  deprecation candidates that remain callable.
- **Seven datasets:** the six exported objects plus `pharmo_example`, loaded with
  `data("pharmo_example", package = "PharmaStatsR")`.
- **Six vignettes:** the original workflow and five covariate guides. See
  [installation](installation.md#worked-vignettes) to build them from GitHub.

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
