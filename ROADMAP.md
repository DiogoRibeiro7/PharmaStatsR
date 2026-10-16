# PharmaStatsR roadmap

## Covariate module consolidation

[Issue #194](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/194) is complete: [PR #195](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/195) merged the full pharmoCovR module with its existing APIs and regression tests. The standalone repository was then deleted. See the [migration guide](docs/covariate-migration.md) for preserved provenance, package references, and method limits. The integration does not resolve the release-candidate gate.

**Status (16 October 2026):** active development, version 0.1.63; not on CRAN. The P0/P1 scope reviews and numerical-reference batches through #165 are complete within their stated scopes. Subsequent method additions and the covariate consolidation are merged. The [API support policy](docs/api-support-policy.md) classifies all 108 exports; the [data guide](docs/simulated-data.md) covers seven datasets, and the package contains six vignettes. The exact-commit release-candidate gate in [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) remains open. A passing check is evidence for tested paths, not validation of every statistical method.

This roadmap orders work by the risk of misleading results and the evidence needed to support the public API. Issues carry the scope and completion criteria; dates and a CRAN submission decision depend on passing the gates below. The [export and evidence inventory](docs/method-inventory.md) identifies methods that still lack independent numerical checks.

## Next sequence

| Order | Work | Reviewable result |
| --- | --- | --- |
| 1 | [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) Release candidate | Use the [inspected `971a37a` baseline](docs/release-candidate.md) and artifact verifier, confirm contact/version/source choices, then check the final merged source and review its receipt before deciding on a tag. The full SAEM example passed and its former timing note is absent from this run. |
| 2 | Training-fold preprocessing integration | Saved numeric imputation (#199), categorical encoding (#201), and [numeric LASSO fold imputation](docs/lasso-imputation.md) (#203) are available with numerical references. [Saved nearest-neighbor donor models](docs/fitted-knn.md) (#205) support numeric targets with mixed predictors. [Nearest-neighbor fold integration](docs/lasso-imputation.md#nearest-neighbor-preprocessing-within-folds) (#207) adds `method = "knn"` to numeric screening. Scope categorical preprocessing within screening folds separately. |
| 3 | Further model and app work | Scope nonstandard names in native mixed models, covariate-aware nonlinear fitting, simulation-based predictive checks, and browser accessibility separately. These are future work, not completed migration features. |

The #123–#125, #129–#131, #136–#138, and #143–#145 implementation batches are
complete. The [batch reconciliation](docs/evidence-batches.md) records the merged
diagnostics and resampling work, the final PR's inspected passing checks, and
its limits. The permutation reference exposed numerical-tie undercounting;
previously affected p-values should be recomputed. PR-head checks are not a new
merged-source artifact receipt for #58.

The #153–#155 missing-data/complex-survival, #159–#160 integration, and #163–#165
reporting/auditability batches are complete. Work in focused PRs with new issues
for substantial methods. The release decision in #58 remains separate.

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
| [#56](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/56) Documentation reconciliation | Closed within original scope | The [reconciliation record](docs/documentation-reconciliation.md) separates the historical 72-export audit from the current 108-export inventory, six vignettes, and source/help/site evidence. Help drift remains gated in CI. |

**Gate:** each supported method has its assumptions, input behavior, numerical evidence, and limitations recorded in [#47](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/47). Changes that alter earlier results have NEWS and migration notes. CI can reproduce its results on a named commit; documentation builds and package checks pass.

## P2 — Stabilize the public API and prepare a release candidate

| Issue | Status | Outcome |
| --- | --- | --- |
| [#57](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/57) Experimental API policy | Closed within scope | All 108 exports have a [support level](docs/api-support-policy.md); the two historical names have migration guidance and remain callable. No export is deprecated or removed. |
| [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) CRAN candidate gate | In progress | The [release record](docs/release-candidate.md) verifies the `971a37a` source hash, five-job matrix, full examples, manuals, and check with one New submission note. The matrix retains a machine-readable receipt; final source/version/contact choices and the release decision remain open. |

**Release gate:** a release candidate is reviewable only after the P0/P1 evidence is complete and [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) records the exact check results. A tag, GitHub release, and CRAN submission are separate decisions. The [portfolio tracking issue](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/21) should reflect the current state rather than an earlier audit snapshot.

## P3 — Strengthen remaining method evidence

The completed #109–#113 and #120 work strengthened evidence for exports whose earlier tests were mainly smoke or backend checks. The next issues target specific numerical gaps in the [inventory](docs/method-inventory.md). Their results do not turn experimental methods into clinically validated methods, and the #58 candidate decision remains separate.

| Issue | Status | Reviewable outcome |
| --- | --- | --- |
| [#109](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/109) Dose-response fits | Closed | Independent Emax and sigmoid-Emax targets, with mixed-fit structure and convergence limits. |
| [#110](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/110) Logistic regression | Closed | Traceable event coding, coefficient and probability references, and boundary behavior. |
| [#111](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/111) Linear mixed model | Closed | Repeated-measure numerical reference, selected population, and failure behavior. |
| [#112](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/112) Bayesian family | Closed | Posterior summaries and predictive checks with a stated reference and Monte Carlo tolerance. |
| [#113](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/113) Meta plots | Closed | Verified plotted coordinates, device effects, and invisible returns. |
| [#120](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/120) Meta study labels | Closed | Fit-time and plot-time `slab` vectors and model-data columns work through the wrappers and are compared with direct backend calls. |
| [#123](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/123) Crossover and Latin-square ANOVA | Closed (#126) | Independent treatment, nuisance, and residual sums of squares, F statistics, and contrasts. |
| [#124](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/124) GEE | Closed (#127) | Cluster-level coefficient and sandwich uncertainty reference. |
| [#125](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/125) Imputation pooling | Closed (#128) | Fixed pooled estimate and uncertainty from Rubin's components. |
| [#129](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/129) Kaplan–Meier and log-rank | Closed (#133) | Fixed risk-set arithmetic, survival steps, and log-rank statistic, with coding, selected rows, and censoring boundaries. |
| [#130](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/130) Ordinary Cox regression | Closed (#134) | Independent Breslow and Efron likelihood, score, coefficient, and model-based uncertainty references, including selected rows and input-order invariance. |
| [#131](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/131) Network meta-analysis | Closed (#135) | Independent common-effect contrasts and covariance, reference treatments, equivalent input orientations and a disconnected-network boundary; the final PR's all-Suggests job passed. |
| [#136](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/136) Counting-process Cox | Closed (#140) | Independent interval-risk-set reference with changing covariates, delayed entry and model-based uncertainty; corrected weight/ID argument forwarding. |
| [#137](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/137) Landmark Cox | Closed (#141) | Independent landmark selection, shifted-time, conditional-risk-set and model-based uncertainty reference. |
| [#138](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/138) No-censoring Fine–Gray | Closed (#142) | Independent subdistribution risk sets, coefficient, pseudo-likelihood, information and baseline-hazard jumps; coefficient covariance remains outside this reference. |
| [#143](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/143) Linear-model diagnostics | Closed (#146) | Independent normal-equation diagnostics, strict cutoffs, affine responses and selected rows; corrected the test's omitted-row leverage expectation to zero. |
| [#144](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/144) Wild bootstrap | Closed (#147) | Independent finite sign-support coefficient draws and moments, seeded ordering, transformed predictors and offsets retained once. |
| [#145](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/145) Permutation F-test | Closed (#148) | Independent 120-permutation support, global F, exact tail counts and sampled p-values; corrected numerical-tie undercounting. |
| [#149](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/149) Unequal-cluster bootstrap | Closed (#151) | Independent 27-sample ledger, pooled-row/equal-copy moments, seeded row/copy identities and callback policies. |
| [#150](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/150) Row bootstrap | Closed (#152) | Independent 27-sample row-mean distribution, exact moments, future-stream execution checks and plan restoration. |
| [#153](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/153) Deterministic multiple imputation | Closed (#156) | Independent observed-column mean targets, exact completed datasets, row identity and affine-transform checks. |
| [#154](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/154) Multistate cumulative hazards | Closed (#157) | Independent transition-specific risk sets, Breslow increments, zero-event omission boundary and time-translation checks. |
| [#155](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/155) Joint-model evidence | Closed (#158) | Independent balanced LME/Cox component targets plus explicitly scoped joint-model backend output contracts. |
| [#159](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/159) SciPy t-test reference | Closed (#161) | Independent Student/Welch formula targets, transformation identities and finite zero-variance boundary. |
| [#160](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/160) Deterministic caret selection | Closed (#162) | Fixed-fold GLM/LDA predictions reconstructed outside caret, plus winner, failure, tie and varImp contracts. |
| [#163](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/163) Report-table numerical reference | Closed (#166) | Independent two-group lm estimates, confidence intervals, p-values and exporter preservation. |
| [#164](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/164) Audit HMAC vectors | Closed (#167) | External fixed HMAC-SHA256 chain vectors, tamper/wrong-key boundaries and valid-prefix limitation. |
| [#165](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/165) SAP artifact contract | Closed | Exact Markdown/file output, UTF-8 and literal-text boundaries, custom-only ordering and validation-before-write preservation. |

Subsequent completed method issues include ANCOVA (#170), CMH (#172), McNemar
(#173), Fisher (#174), Cochran–Armitage (#178), Cochran Q (#179), Stuart–Maxwell
(#180), Bowker (#184), Breslow–Day and its Tarone adjustment (#186/#188), Woolf
(#190), and Mantel–Haenszel common risk ratio (#192). Their per-method guides and
reference tests are linked in the [inventory](docs/method-inventory.md).

## How we work

1. Complete the release decision in #58 when the maintainer confirms its remaining choices. Work through the scoped numerical gaps above while that decision is pending; use the completed [#47 inventory](docs/method-inventory.md) to scope later issues.
2. For a method change, state the estimand or model, allowed data and formula, assumptions, return meaning, and failure cases. Verify a numerical result independently, test a meaningful boundary, update R help/site guidance and NEWS, and link the issue.
3. Keep PRs focused. If a family issue reveals separate defects, split implementation into reviewable PRs linked to that issue. Mark a task complete only when its acceptance criteria and checks are met.
4. Revisit priority after evidence changes. Do not equate test coverage or a green CI badge with suitability for a clinical study.

## Completed groundwork

Completed groundwork includes the [scope audit](docs/claims-audit.md), [core reference cases](docs/core-reference-cases.md), [simulated-data audit](docs/simulated-data.md), and the [cross-platform check policy](docs/development.md). The [limitations guide](docs/limitations.md) records current method-specific constraints. These results support the named paths and fixtures; they are not blanket validation of the package.
