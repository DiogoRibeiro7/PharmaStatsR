# PharmaStatsR roadmap

**Status (1 October 2026):** active development, version 0.1.62; not on CRAN. The routine pull-request gates are an Ubuntu R-release package check and a strict MkDocs build for documentation changes. A separate weekly/manual matrix checks other platforms and R versions, plus an all-Suggests backend path; workflow changes also exercise that matrix on their PR. These checks establish that examples and tests run in those environments. They do not validate every statistical method or constitute a CRAN release check.

This roadmap orders work by the risk of misleading results and the evidence needed to support the public API. It replaces the previous 12-week submission forecast. Issues carry the scope and completion criteria; dates and a CRAN submission decision depend on passing the gates below.

## P0 — Establish scope and numerical evidence

| Issue | Outcome |
| --- | --- |
| [#47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47) Inventory exports and validation evidence | One record per exported symbol; support and review status are explicit. This determines the next focused implementation PRs. |
| [#48](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/48) Audit clinical and regulatory claims | Names, examples, and limits agree with implemented behavior. |
| [#49](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/49) Reference tests for core inference helpers | Independent numerical checks cover estimates, degrees of freedom, intervals, and important boundaries. |

**Gate:** the inventory distinguishes reviewed from unreviewed methods, high-risk claims are qualified, and core calculations have traceable reference cases. A passing package check by itself does not meet this gate.

## P1 — Validate method families and package reliability

| Issue | Outcome |
| --- | --- |
| [#50](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/50) Design and model contracts | Factorial, repeated-measures, and response-surface helpers have defined inputs and tested interpretations. |
| [#51](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/51) Survival and competing risks | Event, censoring, tie, and analysis-row semantics are checked against reference implementations. |
| [#52](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/52) Resampling, permutation, and simulation | Sampling units, RNG behavior, and output interpretation are tested. |
| [#53](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/53) Optional backend and dependency audit | `Imports`/`Suggests` and runtime messages match code paths. |
| [#54](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/54) Cross-platform check matrix | The release check covers relevant R versions and operating systems, with an explicit optional-backend path. |
| [#55](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/55) Simulated dataset audit | Schemas, provenance, and design invariants match the examples. |
| [#56](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/56) Documentation reconciliation | R help, examples, vignettes, and MkDocs describe the same contracts and limitations. |

**Gate:** each supported method has its assumptions, input behavior, numerical evidence, and limitations recorded in [#47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47). Changes that alter earlier results have NEWS and migration notes. CI can reproduce its results on a named commit; documentation builds and package checks pass.

## P2 — Stabilize the public API and prepare a release candidate

| Issue | Outcome |
| --- | --- |
| [#57](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/57) Experimental API policy | Stable, experimental, and example-only exports are distinguished; any deprecation has a migration path. |
| [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) CRAN candidate gate | Metadata, built source package, `R CMD check --as-cran`, vignettes, optional backends, and cross-platform results are checked on one candidate commit. |

**Release gate:** a release candidate is reviewable only after the P0/P1 evidence is complete and [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) records the exact check results. A tag, GitHub release, and CRAN submission are separate decisions. The [portfolio tracking issue](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/21) should reflect the current state rather than an earlier audit snapshot.

## How we work

1. Start with [#47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47). Use its risk ranking to pick the next small method PR instead of selecting helpers opportunistically. The other issues are scoped work, not a promise to implement new methods.
2. For a method change, state the estimand or model, allowed data and formula, assumptions, return meaning, and failure cases. Verify a numerical result independently, test a meaningful boundary, update R help/site guidance and NEWS, and link the issue.
3. Keep PRs focused. If a family issue reveals separate defects, split implementation into reviewable PRs linked to that issue. Mark a task complete only when its acceptance criteria and checks are met.
4. Revisit priority after evidence changes. Do not equate test coverage or a green CI badge with suitability for a clinical study.

## Completed groundwork

The recent fixes include audit-chain and reporting boundaries, competing-risk and survival path corrections, TOST and ANOVA input checks, and design fixes through [#46](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/46). They are starting evidence for the inventory, not a blanket validation of the package. The [limitations guide](docs/limitations.md) records current method-specific constraints.
