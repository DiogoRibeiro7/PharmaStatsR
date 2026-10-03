# PharmaStatsR roadmap

**Status (3 October 2026):** active development, version 0.1.62; not on CRAN. The initial P0 inventory, claims audit, and core reference cases are complete. P1 design contracts, survival and resampling family checks, cross-platform matrix, simulated-data audit, and optional-backend audit are closed; documentation reconciliation remains open. A passing check is evidence for the tested paths, not validation of every statistical method or completion of the release-candidate gate in [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58).

This roadmap orders work by the risk of misleading results and the evidence needed to support the public API. Issues carry the scope and completion criteria; dates and a CRAN submission decision depend on passing the gates below. The [export and evidence inventory](docs/method-inventory.md) identifies methods that still lack independent numerical checks.

## Next sequence

| Order | Issue | Reviewable result |
| --- | --- | --- |
| 1 | [#56](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/56) Documentation | Close remaining help, example, vignette, and site gaps against the implementation and inventory. |
| 2 | [#57](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/57), then [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) | Decide API support policy, then assemble and check one reproducible release candidate. |

## P0 — Establish scope and numerical evidence

| Issue | Status | Outcome |
| --- | --- | --- |
| [#47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47) Inventory exports and validation evidence | Closed | One record per exported symbol and an evidence level for each method; many methods remain candidates for review. |
| [#48](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/48) Audit clinical and regulatory claims | Closed | Sensitive names and examples have qualified descriptions and scope limits. |
| [#49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49) Reference tests for core inference helpers | Closed | Six core helpers have fixed numerical reference cases and stated boundaries. |

**Gate:** the inventory distinguishes reviewed from unreviewed methods, high-risk claims are qualified, and core calculations have traceable reference cases. A passing package check by itself does not meet this gate.

## P1 — Validate method families and package reliability

| Issue | Status | Outcome |
| --- | --- | --- |
| [#50](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/50) Design and model contracts | Closed | Factorial, repeated-measures, and response-surface helpers have defined inputs and tested interpretations. |
| [#51](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/51) Survival and competing risks | Closed | Direct backend cases cover all six listed helpers, with event, censoring, tie, and row-selection assumptions linked from the evidence inventory. |
| [#52](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/52) Resampling, permutation, and simulation | Closed | Deterministic cases cover sampling units, fixed analysis rows, RNG, output shapes, and event/dropout probabilities; the [family review](docs/resampling-review.md) records interpretation limits. |
| [#53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53) Optional backend and dependency audit | Closed | The [entry-point ledger](docs/dependency-audit.md) maps guards and tests; required-dependency checks cover the minimal install, and [the five-job candidate matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37120561275) passed on commit `d06f614`. The separate #58 release gate remains open. |
| [#54](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/54) Cross-platform check matrix | Closed | Weekly/manual checks cover R versions, platforms, and an all-Suggests backend job; candidate runs still need to be recorded under #58. |
| [#55](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/55) Simulated dataset audit | Closed | Schemas, provenance, and design invariants are documented and tested. |
| [#56](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/56) Documentation reconciliation | Open | Generated help has a CI drift gate and the vignette is runnable. Bayesian, meta-analysis, and Emax guides reconcile representative return and model limits; finish the remaining cross-surface review. |

**Gate:** each supported method has its assumptions, input behavior, numerical evidence, and limitations recorded in [#47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47). Changes that alter earlier results have NEWS and migration notes. CI can reproduce its results on a named commit; documentation builds and package checks pass.

## P2 — Stabilize the public API and prepare a release candidate

| Issue | Status | Outcome |
| --- | --- | --- |
| [#57](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/57) Experimental API policy | Open | Stable, experimental, and example-only exports are distinguished; any deprecation has a migration path. |
| [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) CRAN candidate gate | Open | Metadata, built source package, `R CMD check --as-cran`, vignettes, optional backends, and cross-platform results are checked on one candidate commit. |

**Release gate:** a release candidate is reviewable only after the P0/P1 evidence is complete and [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) records the exact check results. A tag, GitHub release, and CRAN submission are separate decisions. The [portfolio tracking issue](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/21) should reflect the current state rather than an earlier audit snapshot.

## How we work

1. Use the completed [#47 inventory](docs/method-inventory.md) to pick a remaining gap in the ordered open issues above. Each issue is scoped work, not a promise to implement new methods.
2. For a method change, state the estimand or model, allowed data and formula, assumptions, return meaning, and failure cases. Verify a numerical result independently, test a meaningful boundary, update R help/site guidance and NEWS, and link the issue.
3. Keep PRs focused. If a family issue reveals separate defects, split implementation into reviewable PRs linked to that issue. Mark a task complete only when its acceptance criteria and checks are met.
4. Revisit priority after evidence changes. Do not equate test coverage or a green CI badge with suitability for a clinical study.

## Completed groundwork

Completed groundwork includes the [scope audit](docs/claims-audit.md), [core reference cases](docs/core-reference-cases.md), [simulated-data audit](docs/simulated-data.md), and the [cross-platform check policy](docs/development.md). The [limitations guide](docs/limitations.md) records current method-specific constraints. These results support the named paths and fixtures; they are not blanket validation of the package.
