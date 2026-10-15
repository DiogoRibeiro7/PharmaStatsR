# Release candidate evidence

Issue [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) tracks a prospective CRAN candidate. This page records checked development evidence and the remaining gate. Version 0.1.63 is **not declared ready for submission**. The [API policy](api-support-policy.md) classifies statistical methods as experimental or example-only.

## Reviewed development baseline: 15 October 2026

[PR #195](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/195) consolidated
pharmoCovR into merged commit
[`65bc1be17fc150e1af42eab6c2b6b33d7f167046`](https://github.com/DiogoRibeiro7/PharmaStatsR/commit/65bc1be17fc150e1af42eab6c2b6b33d7f167046).
This supersedes the 7 October `7057b1b` candidate evidence for the current package:
that earlier tarball does not contain the consolidated module or subsequent
methods. The version number alone does not identify the checked source.

All five jobs in [matrix run 38801594182](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182)
passed on `65bc1be`:

| Environment | Result |
| --- | --- |
| [macOS / R release / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182/job/116651727912) | Passed |
| [Windows / R release / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182/job/116651729552) | Passed |
| [Ubuntu / R oldrel-1 / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182/job/116651728733) | Passed |
| [Ubuntu / R devel / required](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182/job/116651727640) | Passed |
| [Ubuntu / R release / all Suggests](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182/job/116651727500) | Passed, including SciPy, vignette rebuilding, and PDF/HTML manuals |

The [routine R checks](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594157)
and [documentation build/deployment](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594029)
also passed on that SHA.

### Inspected source artifact

The downloaded [source/check artifact](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182/artifacts/12005470526)
contains `PharmaStatsR_0.1.63.tar.gz`, a manifest and commit marker, check and
install logs, example plots, and the PDF manual. Its commit marker matches
`65bc1be17fc150e1af42eab6c2b6b33d7f167046`.

- Source size: **437,317 bytes**, with **365 archive entries**.
- SHA-256, independently recalculated from the downloaded tarball:
  `b00c781b2ebbc79f1635959190df7c9aa5fd8fd9cda5300c4351a51b44e153b4`.
- Inspection confirmed source, help, tests, six vignette sources, the built
  `pharmo_example.rda` dataset, report/app resources, citation, and both license
  records. Development-only `docs/`, `scripts/`, `.github/`, and `data-raw/`
  directories are absent.

On Ubuntu 24.04.5 with R 4.6.1 and every Suggested package installed,
`R CMD check --as-cran` reported **0 errors, 0 warnings, and 2 notes**:

1. **New submission**, from CRAN incoming feasibility.
2. **Example runtime**, for `fit_nlmixr_model()`: 9 seconds elapsed and 13.166
   seconds CPU in this run. Review or reduce this example's cost before a
   submission; a passing CI result does not accept it as an exception.

Examples, tests, vignette rebuilding, and PDF/HTML manual checks passed. The
four required-dependency portability jobs use `--no-manual`.

This receipt applies only to `65bc1be`. The documentation refresh itself changes
packaged README/NEWS content, so a later merged commit needs its own matrix,
artifact, hash, and note review before it can become a final candidate.

### Follow-up: classify the lengthy SAEM example

The `fit_nlmixr_model()` help now marks its full SAEM example with
`\donttest{}`, following the [CRAN guidance for lengthy examples](https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples).
The estimator, default iterations, example dataset, and backend integration
test remain unchanged. `R CMD check --as-cran` runs the lengthy example in its
separate `checking examples with --run-donttest` pass. Verify that pass as well
as the full-data test when reviewing the new all-Suggests artifact.

The two notes above remain the historical result for `65bc1be`. Do not reuse
that result or hash for the changed source; record the final merged check and
its actual notes before a release decision.

## One commit, one source package

1. Finish metadata, help, tests, vignette, NEWS, and the prospective [`cran-comments.md`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/cran-comments.md) on a PR. The package maintainer must verify that the existing address in `DESCRIPTION` can receive CRAN correspondence and that the recorded institutional affiliation is current. Any change to the public contact fields needs the maintainer's choice.
2. Review the PR checks. The [R validation matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-validation-matrix.yaml) checks out the PR **head SHA** in every job. Its four portability jobs use the required dependency set; the Ubuntu all-Suggests job installs and logs every Suggested R package, builds a source tarball, lists its contents, records its SHA-256 and commit SHA, and runs `R CMD check --as-cran` with TinyTeX and HTML Tidy on that tarball. The workflow uploads the tarball, manifest, hash, check log, and generated PDF manual, including available evidence when the check fails.
3. After the PR is merged, record a matrix run on the exact `main` commit. Merges that change package source, candidate comments, or the matrix workflow start one automatically; otherwise select `main` in **Run workflow**. Record the SHA and all five job links in #58. Earlier matrix runs and PR-head runs are useful comparisons, but only the final merged candidate commit proves its source passed.
4. Inspect the downloaded tarball, `candidate-contents.txt`, `candidate-sha256.txt`, `PharmaStatsR.Rcheck/00check.log`, and generated PDF manual. Check that source, help, license, tests, and vignettes are present and that development-only directories are absent. Check the reported examples, tests, vignette, and manual outcome, not just the job colour. Explain each NOTE or failure in `cran-comments.md`; repair and rerun on a new exact SHA unless a reviewer accepts a documented exception.
5. Only after the exact merged SHA and evidence are reviewed, choose a candidate tag for that SHA and record it in #58. A tag, GitHub release, and CRAN submission require separate decisions. If the source changes after the check, repeat the matrix and review; the earlier hash does not apply.

| Evidence | Current state |
| --- | --- |
| Metadata: author/contact, package title, URLs, MIT license, dependencies, citation, NEWS | Title and project URLs reviewed; maintainer designated the public address and current affiliation. Check mail receipt and choose the final version before tagging. |
| Built tarball contents, SHA-256, examples, tests, vignettes, CRAN-style check | Reviewed for `65bc1be` above. Repeat for the final merged source after this documentation refresh. |
| macOS/Windows R release, Ubuntu R old release/devel, Ubuntu all-Suggests | All five passed on `65bc1be`; the full job also checked PDF/HTML manuals. |
| `cran-comments.md` with environments and explained NOTEs | Draft records the historical notes and the lengthy-example change. Verify the separate `--run-donttest` pass and update the notes for the final merged source. |
| Candidate tag and [#21 portfolio tracker](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/21) | Select the final source/version and record the maintainer's separate release decision in #58. No new tag or submission follows from this receipt. |

## Policy review before submission

Read the current [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html) and [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html) against the **built** package. In particular, check maintainer reachability and authorship, license and source provenance, dependency availability and conditional use of Suggested packages, portability on major R platforms, package size and check time, short examples, and writes confined to permitted locations unless explicitly requested by the caller. The all-Suggests job builds the manual, while the four portability jobs still use `--no-manual`; review the PDF and its log on the exact candidate run. CRAN's incoming and platform checks can differ from these CI environments; a green matrix is evidence for the recorded runs, not acceptance by CRAN or suitability for a clinical analysis.
