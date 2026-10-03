# Project status

**3 October 2026 · version 0.1.62 · active development · not on CRAN**

The [repository roadmap](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/ROADMAP.md) is the detailed plan. Its issues define completion criteria. Closing an issue records work within that scope; it does not validate every exported method or qualify the package for clinical decisions.

| Phase | Closed work | Open work |
| --- | --- | --- |
| P0: scope and initial numerical evidence | [Export inventory #47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47), [claims audit #48](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/48), [core reference cases #49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49) | Individual methods in the [evidence inventory](method-inventory.md) still await review. |
| P1: method families and reliability | [Design contracts #50](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/50), [survival family #51](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/51), [resampling review #52](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/52), [optional backends #53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53), [check matrix #54](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/54), [simulated-data audit #55](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/55) | [Documentation reconciliation #56](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/56). |
| P2: API and release | — | [Support policy #57](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/57), then [candidate gate #58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58). |

## What the evidence means

- The [reference cases](core-reference-cases.md) fix expected values for six core inference helpers. They do not cover all methods or datasets.
- The [method inventory](method-inventory.md) labels representative tests as numerical references, behavior comparisons, smoke checks, or backend guards. Many public exports remain candidate APIs pending an independent method review.
- The [validation matrix](development.md#package-checks) and routine PR checks exercise the package in named environments. Their success establishes software-check results for those commits, not study-specific statistical validity.
- [Limitations and validation](limitations.md) describes known method and workflow boundaries.

The next sequence is to finish #56's package-wide help review and example/vignette verification, decide the API support policy in #57, then assemble a reproducible candidate in #58. Every export now has a site guide, scope page, or reference link in the [inventory](method-inventory.md); that coverage does not establish complete method validation. The [#53 candidate matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37120561275) passed all five jobs; a separate release-candidate run remains necessary under #58. No CRAN submission date is promised before the candidate gate is reviewed.
