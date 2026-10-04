# Project status

**4 October 2026 · version 0.1.62 · active development · not on CRAN**

The [repository roadmap](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/ROADMAP.md) is the detailed plan. Its issues define completion criteria. Closing an issue records work within that scope; it does not validate every exported method or qualify the package for clinical decisions.

| Phase | Closed work | Open work |
| --- | --- | --- |
| P0: scope and initial numerical evidence | [Export inventory #47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47), [claims audit #48](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/48), [core reference cases #49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49) | Individual methods in the [evidence inventory](method-inventory.md) still await review. |
| P1: method families and reliability | [Design contracts #50](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/50), [survival family #51](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/51), [resampling review #52](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/52), [optional backends #53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53), [check matrix #54](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/54), [simulated-data audit #55](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/55), [documentation reconciliation #56](documentation-reconciliation.md) | Individual methods in the [evidence inventory](method-inventory.md) still await independent review. |
| P2: API and release | [Support policy #57](api-support-policy.md) classifies all 72 exports, with migration guidance for historical names. | [Candidate gate #58](release-candidate.md) records the latest exact main-commit evidence; the designated contact and affiliation are recorded, while final version and tag decisions remain. |
| P3: stronger method evidence | The [inventory](method-inventory.md) distinguishes numerical references from smoke checks. | [Dose response #109](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/109), [logistic #110](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/110), [mixed model #111](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/111), [Bayesian #112](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/112), and [meta plots #113](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/113) are open. |

## What the evidence means

- The [reference cases](core-reference-cases.md) fix expected values for six core inference helpers. They do not cover all methods or datasets.
- The [method inventory](method-inventory.md) gives every export a [support level](api-support-policy.md) and labels representative tests as numerical references, behavior comparisons, smoke checks, or backend guards. All statistical methods remain experimental pending independent review.
- The [validation matrix](development.md#package-checks) and routine PR checks exercise the package in named environments. Their success establishes software-check results for those commits, not study-specific statistical validity.
- [Limitations and validation](limitations.md) describes known method and workflow boundaries.

The next sequence is to run the [candidate gate](release-candidate.md) in #58 under the [support policy](api-support-policy.md). The [documentation reconciliation](documentation-reconciliation.md) records help, example, vignette, and site evidence; it does not establish complete method validation. The [current merged-commit matrix and source artifact](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) are recorded under #58. Any later source change needs its own exact-commit check before a candidate tag. No CRAN submission date is promised before the candidate gate is reviewed.
