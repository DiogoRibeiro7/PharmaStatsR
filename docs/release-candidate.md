# Release candidate evidence

Issue [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) tracks the
prospective CRAN candidate and subsequent check receipts. Version 0.1.63 remains
in development. This page records a reviewed baseline and a repeatable artifact
check; the [API policy](api-support-policy.md) still classifies statistical
methods as experimental or example-only.

## Reviewed development baseline: 15 October 2026

[PR #197](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/197) merged as
[`971a37aaf203fad523807c254db930ce588ccbcd`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/971a37aaf203fad523807c254db930ce588ccbcd).
This source includes the pharmoCovR consolidation, refreshed documentation, and
the lengthy SAEM example classification. All five jobs in
[matrix run 38814107301](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301)
passed on that commit:

| Environment | Result |
| --- | --- |
| [macOS / R release / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301/job/116694334451) | Passed |
| [Windows / R release / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301/job/116694334528) | Passed |
| [Ubuntu / R oldrel-1 / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301/job/116694334450) | Passed |
| [Ubuntu / R devel / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301/job/116694334375) | Passed |
| [Ubuntu / R release / all Suggests](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301/job/116694334090) | Passed, including SciPy, vignette rebuilding, and PDF/HTML manuals |

The [routine R checks](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107541)
and [documentation build/deployment](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107402)
also passed on that SHA.

### Inspected source artifact

The downloaded [source/check artifact](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301/artifacts/12010840213)
contains the source tarball, manifest, checksum, commit marker, check/install
logs, example plots, and PDF manual. Independent verification confirmed:

- Source: `PharmaStatsR_0.1.63.tar.gz`, **438,365 bytes**, **365 archive entries**.
- SHA-256: `0ec1a1447d6b55719ecd8aae122080c742a314a2dedc8d7235026c53c42e705c`.
- Commit marker: `971a37aaf203fad523807c254db930ce588ccbcd`.
- Source, help, tests, all six vignette sources, `pharmo_example.rda`, report/app
  resources, citation, package license, and imported MIT notice are present.
- Development-only `docs/`, `scripts/`, `.github/`, and `data-raw/` directories
  are absent. The manifest matches the actual archive members.

On Ubuntu 24.04.5 with R 4.6.1 and every Suggested package installed,
`R CMD check --as-cran` reported **0 errors, 0 warnings, and 1 NOTE**:
**New submission**, from CRAN incoming feasibility.

Ordinary examples passed in 23 seconds elapsed. The separate
`checking examples with --run-donttest` pass, including the full SAEM fit,
passed in 50 seconds elapsed (41 seconds CPU). Tests, vignette rebuilding, and
PDF/HTML manuals also passed. The four portability jobs use `--no-manual`.

The full SAEM example is classified with `\donttest{}` according to
[CRAN's lengthy-example guidance](https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples).
Its estimator, default iterations, dataset, and full-data backend test are
unchanged. The earlier `65bc1be` consolidation artifact had two notes, including
example runtime; the timing note is absent from this merged run. Timing remains
environment-dependent: the local Windows check of PR #197 recorded a separate
existing caret-example timing note, which was absent from the Ubuntu CI check.

This receipt applies only to `971a37a`. Changes to packaged README/NEWS content
also change the source. Record later merged receipts in #58; a routine evidence
update does not require another documentation PR just to replace this historical
snapshot. Neither the earlier `65bc1be` artifact nor the superseded 7 October
`7057b1b` candidate establishes readiness for later source.

## Verify a downloaded artifact

From a checkout containing the verifier, use Python 3.10 or later and the GitHub
CLI. The verifier itself uses only the Python standard library. For this
reviewed baseline, run:

```bash
gh run download 38814107301 --repo DiogoRibeiro7/PharmaStatsR --name candidate-source-ubuntu-all-suggests --dir candidate-evidence
python scripts/verify_release_artifact.py candidate-evidence --commit 971a37aaf203fad523807c254db930ce588ccbcd
```

Use a fresh destination directory. For a later candidate, supply its run ID and
full checkout SHA from the Actions run and compare that SHA with the intended
merged commit. PR runs check the PR head; a PR-head receipt does not establish
that the later merge passed. Download artifacts while their retention period
is active and retain the source/evidence selected for an actual release.

The verifier reads the tarball without extracting it. It checks the commit
marker, recalculated SHA-256, filename/description/check-log version agreement,
manifest, required package resources, and absence of development directories.
It rejects unsafe/duplicate archive paths, links, empty files, incomplete logs,
errors, warnings, and missing required check passes. Ordinary examples,
`--run-donttest` examples, tests, vignette rebuilding, and PDF/HTML manuals must
finish with OK or a reported NOTE. Successful installation output and a PDF
manual are also required.

The command prints JSON with the source identity, size, hash, and every NOTE.
The all-Suggests workflow runs the same verifier and retains its output as
`candidate-verification.json` for new runs. To test the verifier locally:

```bash
python -m unittest discover -s scripts/tests -v
```

These are consistency checks on the downloaded evidence, not a cryptographic
attestation that the marker, source, and logs came from that commit. Use the
trusted repository's Actions run to establish provenance. Human review still
covers the NOTE text, PDF rendering, dependency versions and backend coverage,
current policy, and maintainer choices. A JSON receipt is not release approval.

## One commit, one source package

1. Finish package metadata, help, tests, vignettes, NEWS, and the prospective
   [`cran-comments.md`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/cran-comments.md)
   on a PR. The maintainer must confirm that the public `DESCRIPTION` address
   receives CRAN correspondence, review affiliation, and choose the final version.
2. Review PR checks. The matrix checks out the PR head SHA; four jobs use required
   dependencies, and Ubuntu installs/logs all Suggests, builds and checks the
   tarball with manuals, verifies evidence, and uploads the receipt and artifacts.
3. After merging, record the matrix on the exact selected `main` commit in #58.
   Package, candidate-comment, verifier, and matrix-workflow changes trigger it;
   otherwise select `main` in **Run workflow**. Record all five job links, the
   checkout SHA, artifact link, hash, and actual check results.
4. Download and verify that artifact. Read every NOTE and inspect the manual,
   logs, backend coverage, and package contents. Repair findings and check a new
   exact source unless a reviewer explicitly accepts a documented exception.
5. Choose a candidate tag only after selecting and reviewing that exact source.
   Tagging, a GitHub release, and CRAN submission are separate maintainer decisions.
   Source changes require another check; a matching version is not a matching hash.

| Evidence | Current state |
| --- | --- |
| Public maintainer metadata | Existing address/affiliation recorded; mail receipt and final version/source selection still need confirmation. |
| Source artifact, checks, and NOTEs | Reviewed for `971a37a` above: 0 errors, 0 warnings, 1 New submission note. Later receipts belong in #58. |
| macOS/Windows release, Ubuntu oldrel/devel, all Suggests | All five passed on `971a37a`; the full job also checked PDF/HTML manuals and lengthy examples. |
| `cran-comments.md` | Draft records this named baseline; replace it with the chosen final candidate's actual results before submission. |
| Candidate tag, release, and submission | Maintainer decisions pending in #58 and the [#21 tracker](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/21). |

## Policy review before submission

Read the current [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html)
and [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)
against the built package. Review maintainer reachability and authorship,
licensing/source provenance, dependency availability and conditional Suggests,
portability, size and check time, examples, and permitted file writes. CRAN's
incoming/platform checks can differ from CI. Successful recorded checks do not
establish CRAN acceptance or suitability for a clinical analysis.
