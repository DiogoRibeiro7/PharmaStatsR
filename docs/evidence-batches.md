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

## Current batch: diagnostics and resampling, #143–#145

All three issues were created before implementation. The first reference is
supplied alongside this record; its own PR checks and review must establish
acceptance. The two resampling items remain planned, not completed evidence.

| Order | Issue | Reviewable result |
| --- | --- | --- |
| 1 | [#143: linear-model diagnostics](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/143) | [Independent unweighted OLS diagnostics](model-diagnostics.md): fixed residuals, hat diagonals, standardized residuals, Cook's distances, strict cutoffs, missing-row policy and affine-response invariance. |
| 2 | [#144: wild bootstrap](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/144) | Independent finite sign-support coefficient draws, conditional mean and covariance, offsets and transformed terms. |
| 3 | [#145: permutation F-test](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/145) | Independent global F statistic, a small enumerated permutation support, upper-tail counts, Monte Carlo correction and numerical tie boundaries. |

Implement one focused PR at a time, in this order. Each issue defines its
acceptance criteria, assumptions, numerical tolerances to record, and exclusions.
Preserve existing input-contract and optional-backend tests. Promote an evidence
label only with a reviewable independent calculation and passing checks in the
appropriate dependency environment. Record newly discovered defects separately
rather than expanding a reference task into an unrelated framework.

After these three reviews, reconcile the batch and reassess the inventory before
opening another implementation sequence. No new API, dependency, package version,
release tag, or submission is authorized by this planning record. The remaining
maintainer decisions and exact-source release evidence remain in #58.
