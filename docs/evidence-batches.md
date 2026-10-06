# Method-evidence batches

This record reconciles scoped method work and identifies the next review queue.
It is not a release checklist or a package-wide validation statement. The
[export inventory](method-inventory.md) remains the per-function evidence ledger;
the [API support policy](api-support-policy.md) remains unchanged.

## Completed batch: #129–#131

Reconciled on 5 October 2026 after [PR #135](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/135)
merged as [`8e4a0d4`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/8e4a0d4415ca09359390e85d11fc57cdfd5edebb).
All three implementations are in that source tree. Their numerical-reference
labels supplement the existing contract/backend-comparison tests; statistical
methods remain experimental.

| Issue and merged PR | Independent evidence added | Important untested boundaries |
| --- | --- | --- |
| [#129](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/129), [#133](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/133) | [Kaplan–Meier and log-rank](kaplan-meier.md): fixed risk sets, survival steps, observed/expected event counts, covariance, coding and row-selection checks. | Confidence intervals, near-tie correction, weighted/stratified comparisons, delayed entry and competing events. |
| [#130](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/130), [#134](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/134) | [Ordinary Cox](survival-regression.md): independent Breslow/Efron likelihood, score, coefficient, model-based uncertainty and selected rows. | Robust variances, baseline hazards, predictions, multivariable models and counting-process risk sets. |
| [#131](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/131), [#135](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/135) | [Network meta-analysis](network-meta-analysis.md): common-effect weighted contrasts, full contrast covariance, orientation, reference treatments and disconnected-network failure. | Transitivity, study consistency, multi-arm adjustment, random-effects estimation and rankings. |

### Checked CI evidence

The results below belong to the final batch PR's head commit,
[`c0cf41a`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/c0cf41aedb3e1b92596ce071daf990f0ca261643),
not to its later merge commit. This head already contains the earlier merged
Kaplan–Meier and ordinary Cox reference tests.

| Workflow or job | Observed result |
| --- | --- |
| [Routine R package checks](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37278847371) | Success |
| [Strict documentation build](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37278847270) | Success |
| [Five-job R validation matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37278847205) | All five jobs succeeded |
| [Ubuntu R release / all Suggests](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/jobs/111661914783) | Suggested-package verification, source build/inspection and CRAN-style source check steps succeeded |

The all-Suggests workflow verifies optional packages are installed before running
the package check, so the network reference is not intentionally skipped for a
missing `netmeta` backend there. Required-only portability jobs have a different
dependency scope. See the [check policy](development.md) and each test's guards.

This reconciliation inspected workflow/job statuses and the linked source scope.
It does not claim a new source-tarball hash verification, manual inspection, or
exact merged-commit release review. Those records belong to
[#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) and the
[release-candidate checklist](release-candidate.md). Earlier artifact receipts
remain evidence for their own named commits; they must not be relabelled as
receipts for a later source tree.

## Completed batch: #136–#138

Reconciled on 5 October 2026 after [PR #142](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/142)
merged as [`78d632c`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/78d632cb3bd0c1fba90b357a377b0065e7084003).
The counting-process, landmark, and no-censoring Fine–Gray references are all in
that tree. Each numerical-reference label supplements existing contract tests
and retains experimental support status.

| Issue and merged PR | Independent evidence added | Important untested boundaries |
| --- | --- | --- |
| [#136](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/136), [#140](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/140) | [Counting-process Cox](cox-timevarying.md): interval risk sets, changing exposure, delayed entry, likelihood, model-based uncertainty, selected rows and interval splitting. The reference also exposed and led to correction of weight/ID argument forwarding. | Robust variances, recurrent events, arbitrary subject histories, event-time ties, near-tie correction and causal exposure effects. |
| [#137](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/137), [#141](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/141) | [Landmark Cox](landmark-analysis.md): strict eligibility, shifted time origin, subject identities, Breslow likelihood, model-based uncertainty and missing-data boundaries. | Data-driven landmark choice, causal effects, robust variances, time-varying covariates and prediction calibration. |
| [#138](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/138), [#142](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/142) | [No-censoring Fine–Gray](competing-risks.md): retained competing-event subjects, coefficient, pseudo-likelihood, score, information, inverse information and baseline-hazard jumps. | Estimated censoring weights, censoring groups, coefficient covariance, tied events, time-varying effects and predictions. |

### Checked survival-batch CI evidence

These results belong to the final PR head
[`95107ee`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/95107ee8239db158aca72005d6805c495bb3f6e4),
which includes the earlier merged counting-process and landmark work. They are
not results for the later merge commit or for the diagnostics implementation.

| Workflow or job | Observed result |
| --- | --- |
| [Routine R package checks](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37335771876) | Success |
| [Strict documentation build](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37335771956) | Success |
| [Five-job R validation matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37335771812) | All five jobs succeeded |
| [Ubuntu R release / all Suggests](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/jobs/111850043611) | Suggested-package verification, source build/inspection and CRAN-style source check steps succeeded |

The all-Suggests job verifies `cmprsk` is installed, so the fitted Fine–Gray
reference runs there rather than skipping for an absent backend. The arithmetic
risk-table test also runs without that optional package. Workflow/job evidence
for this PR head does not replace the separate exact-merged-source release gate
in #58. No tag or CRAN submission decision is made by this reconciliation.

## Completed batch: #143–#145

Reconciled on 5 October 2026 after [PR #148](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/148)
merged as [`60f2351`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/60f235198f5c6c9f10d5af4841b00c2719d726cb).
All three implementations are in that source tree.

| Issue and merged PR | Independent evidence added | Important untested boundaries |
| --- | --- | --- |
| [#143](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/143), [#146](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/146) | [Linear-model diagnostics](model-diagnostics.md): normal-equation residuals, leverage, standardized residuals, Cook's distances, strict cutoffs and selected rows. The new test was corrected to expect zero leverage in omitted positions restored by `na.exclude`, with other measures and flags missing. | GLM diagnostics, weighted/rank-deficient fits, formal outlier tests and automatic row deletion. |
| [#144](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/144), [#147](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/147) | [Wild bootstrap](wild-bootstrap.md): all 16 sign patterns, exact coefficient mean/covariance, seeded order, transformed predictors and offsets retained once. | Leverage corrections, dependent observations and interval coverage. |
| [#145](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/145), [#148](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/148) | [Permutation F-test](permutation.md): 120 labelled permutations, global F, exact tail counts, sampled p-values and row policies. Production upper-tail counting now includes numerical ties. | Restricted permutations, nuisance-adjusted partial tests, dependent rows and general operating characteristics. |

### Checked diagnostics/resampling CI evidence

These results belong to final PR head
[`0c44b0e`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/0c44b0e65d015227b08a1091be1e766939ab5afb),
which includes the earlier merged diagnostics and wild-bootstrap references.
They are not results for the new cluster-bootstrap reference or a later merge.

| Workflow or job | Observed result |
| --- | --- |
| [Routine R package checks](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37377237145) | Success |
| [Strict documentation build](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37377237103) | Success |
| [Five-job R validation matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37377237135) | All five jobs succeeded |
| [Ubuntu R release / all Suggests](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/jobs/111989447475) | Suggested-package verification, source build/inspection and CRAN-style source check steps succeeded |

The new references in this batch require no optional backend. The permutation
correction affects only p-value comparisons, not returned F values or sampled
permutations. The method guide and NEWS record the migration note. This record
inspects workflow/job statuses; it does not claim a newly downloaded tarball hash,
manual inspection, or exact-merged-source release receipt. #58 remains separate.

## Completed batch: cases bootstrap, #149–#150

Both issues were defined before implementation and are now merged. #151 adds the
unequal-cluster reference and #152 adds the finite-support row-bootstrap reference.
Both remain conditional method evidence rather than coverage or study-validity claims.

| Order | Issue | Reviewable result |
| --- | --- | --- |
| 1 | [#149: unequal-cluster bootstrap](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/149) | [Independent cluster-size/total ledger](cluster-bootstrap.md): all 27 ordered samples, pooled-row and equal-copy means, conditional moments, row/copy identities and callback missing-value policies. |
| 2 | [#150: row bootstrap](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/150) | [Independent row support](parallel-bootstrap.md): all 27 three-row samples, exact mean/variance, seeded future-stream execution, callback policies and plan restoration. |

The final #152 PR head passed its routine R check, strict documentation build and five-job validation matrix before merge. These PR-head results do not replace the exact-merged-source release evidence required by #58.

## Completed batch: missing data and complex survival, #153–#155

All three issues were created before implementation. The deterministic imputation reference is first because its numerical targets are directly reconstructible without a second imputation run.

| Order | Issue | Reviewable result |
| --- | --- | --- |
| 1 | [#153: deterministic multiple imputation](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/153) | [Deterministic mean-imputation reference](missing-data.md#independent-deterministic-imputation-reference): fixed observed-column means, exact imputed cells/completed datasets, method and predictor-matrix contract, row identity and affine transformations. Merged in #156. |
| 2 | [#154: multistate cumulative hazards](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/154) | [Independent multistate reference](multistate.md#independent-cumulative-hazard-reference): transition risk sets, Breslow increments, delayed-entry boundary, zero-event transition omission, row order and time translation. Merged in #157. |
| 3 | [#155: joint-model evidence](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/155) | [Layered joint-model evidence](joint-model.md#evidence-layers): independent balanced LME/Cox component targets, with fitted joint-model quantities explicitly classified as backend contracts. Merged in #158. |

Implement one focused PR at a time. No new public API, dependency, package version, release tag or submission is authorized by this planning record.


### Checked #153–#155 CI evidence

The final batch PR head `4a8964e` contains the earlier merged deterministic
imputation and multistate references. Its routine R package check, strict
documentation build, and all five validation-matrix jobs passed before merge.
The Ubuntu all-Suggests job exercised JM and the optional statistical backends.

These PR-head results support this method-evidence batch. They are not a new
exact-merged-source artifact receipt for the separate release gate in #58.

## Current batch: statistical integrations, #159–#160

Both issues were created before implementation.

| Order | Issue | Reviewable result |
| --- | --- | --- |
| 1 | [#159: SciPy t-test reference](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/159) | [Independent SciPy bridge reference](scipy-bridge.md#independent-numerical-reference): Student/Welch sample-moment formulas, standard errors, degrees of freedom, statistics, t-tail p-values, transformations and a finite zero-variance boundary. Merged in #161. |
| 2 | [#160: deterministic caret selection](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/160) | [Fixed-fold selection reference](model-selection.md#fixed-fold-selection-reference): direct GLM and base-R LDA hold-out predictions reconstruct the winner; remaining caret object behavior is classified as contract evidence. |

Implement one focused PR at a time. No release tag, submission, new required
dependency, or broad API expansion is authorized by this planning record.
