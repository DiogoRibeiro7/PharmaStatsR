# Project status

**15 October 2026 · version 0.1.63 · active development · not on CRAN**

The [repository roadmap](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/ROADMAP.md) is the detailed plan. Its issues define completion criteria. Closing an issue records work within that scope; it does not validate every exported method or qualify the package for clinical decisions.

| Phase | Closed work | Open work |
| --- | --- | --- |
| P0: scope and initial numerical evidence | [Export inventory #47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47), [claims audit #48](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/48), [core reference cases #49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49) | Individual methods in the [evidence inventory](method-inventory.md) still await review. |
| P1: method families and reliability | [Design contracts #50](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/50), [survival family #51](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/51), [resampling review #52](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/52), [optional backends #53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53), [check matrix #54](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/54), [simulated-data audit #55](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/55), [documentation reconciliation #56](documentation-reconciliation.md) | Individual methods in the [evidence inventory](method-inventory.md) still await independent review. |
| P2: API and release | [Support policy #57](api-support-policy.md) classifies all 101 exports, with migration guidance for historical names. The inspected `65bc1be` source passed its five-job matrix and full all-Suggests check. | [Candidate gate #58](release-candidate.md) remains open: review both notes, confirm mail receipt and final version/source, rerun checks after changes, and make the release decision. |
| P3: stronger method evidence | The scoped numerical-reference batches through [reporting/auditability #163–#165](evidence-batches.md#completed-batch-reporting-and-auditability-163165) are complete, as are the subsequent categorical-outcome and stratified-risk helpers recorded in the inventory. | Further gaps in the [inventory](method-inventory.md) need individual issues and review. |
| Covariate consolidation | [#194](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/194) closed with [PR #195](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/195): 18 functions, regression tests, data, five vignettes, reports, and app resources now live here. The standalone pharmoCovR repository was deleted. | The [migration guide](covariate-migration.md) records remaining limits: training-fold preprocessing, reusable imputation/encoding, nonlinear covariate models, predictive simulation, and browser checks. |

## Current package inventory

- **101 namespace exports:** 95 functions and six illustrative data objects.
- **Support labels:** two stable, 86 experimental, 11 example-only, and two
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

## Latest checked source and remaining release work

The [reviewed development baseline](release-candidate.md#reviewed-development-baseline-15-october-2026)
is merged commit `65bc1be17fc150e1af42eab6c2b6b33d7f167046`. The routine R checks,
documentation build/deployment, and all five matrix jobs passed. Inspection of
the all-Suggests artifact confirmed **0 errors, 0 warnings, and 2 notes**:
new submission and the nlmixr2 example runtime. The source hash and job links
are recorded in the release evidence.

The older 7 October candidate does not contain the consolidated package.
The documentation refresh also changes packaged README/NEWS content; final
candidate selection requires checks of its own merged source. Review the
runtime note, maintainer contact, final version, comments, and tag decision
under [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58).
The [documentation reconciliation](documentation-reconciliation.md) separates
current coverage from historical audits. No CRAN submission date is set.
