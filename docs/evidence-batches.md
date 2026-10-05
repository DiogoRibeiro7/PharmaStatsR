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

## Next batch: survival extensions

The following three issues were created together before implementation. Their
existing inventory entries remain at contract/backend-comparison level [C].
A planned reference is not completed numerical evidence.

| Order | Issue | Reviewable result |
| --- | --- | --- |
| 1 | [#136: counting-process Cox](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/136) | Explicit interval risk sets, a changing covariate and delayed entry; independent likelihood, coefficient and model-based covariance, including interval-splitting invariance. |
| 2 | [#137: landmark Cox](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/137) | Independently checked eligibility at a fixed landmark, shifted times, selected subject identities, likelihood and model-based covariance. |
| 3 | [#138: no-censoring Fine–Gray](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/138) | Explicit subdistribution risk sets, independent coefficient, pseudo-likelihood, information and baseline-hazard jumps; covariance needs separate evidence. |

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
