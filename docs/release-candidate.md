# Release candidate evidence

Issue [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) tracks a prospective CRAN candidate. This page defines the gate; it does **not** declare version 0.1.62 ready or authorize submission. The [API policy](api-support-policy.md) still marks all statistical methods experimental.

## One commit, one source package

1. Finish metadata, help, tests, vignette, NEWS, and the prospective [`cran-comments.md`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/cran-comments.md) on a PR. The package maintainer must verify that the existing address in `DESCRIPTION` can receive CRAN correspondence and that the recorded institutional affiliation is current. Any change to the public contact fields needs the maintainer's choice.
2. Review the PR checks. The [R validation matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-validation-matrix.yaml) checks out the PR **head SHA** in every job. Its four portability jobs use the required dependency set; the Ubuntu all-Suggests job installs and logs every Suggested R package, builds a source tarball, lists its contents, records its SHA-256 and commit SHA, and runs `R CMD check --no-manual --as-cran` on that tarball. The workflow uploads the tarball, manifest, hash, and check log, including when the check fails.
3. After the PR is merged, select `main` in **Run workflow** for the matrix. Record the exact main commit SHA and all five job links in #58. A previous matrix run on `d06f614` and a PR-head run are useful comparisons, but neither proves a later merged candidate commit passed.
4. Inspect the downloaded tarball, `candidate-contents.txt`, `candidate-sha256.txt`, and `PharmaStatsR.Rcheck/00check.log`. Check that source, help, license, tests, and vignettes are present and that development-only directories are absent. Check the reported examples, tests, and vignette outcome, not just the job colour. Explain each NOTE or failure in `cran-comments.md`; repair and rerun on a new exact SHA unless a reviewer accepts a documented exception.
5. Only after the exact merged SHA and evidence are reviewed, choose a candidate tag for that SHA and record it in #58. A tag, GitHub release, and CRAN submission require separate decisions. If the source changes after the check, repeat the matrix and review; the earlier hash does not apply.

| Evidence | Current state |
| --- | --- |
| Metadata: author/contact, package title, URLs, MIT license, dependencies, citation, NEWS | Title and project URLs reviewed; verify existing maintainer email, affiliation, and final release version before tagging. |
| Built tarball contents, SHA-256, examples, tests, vignettes, CRAN-style check | Pending on the exact merged candidate commit. |
| macOS/Windows R release, Ubuntu R old release/devel, Ubuntu all-Suggests | An earlier five-job run is recorded in [#53](dependency-audit.md); candidate SHA run pending. |
| `cran-comments.md` with environments and explained NOTEs | Draft only; populate from the exact candidate logs. |
| Candidate tag and #21 portfolio tracker | Pending candidate evidence and review. |

## Policy review before submission

Read the current [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html) and [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html) against the **built** package. In particular, check maintainer reachability and authorship, license and source provenance, dependency availability and conditional use of Suggested packages, portability on major R platforms, package size and check time, short examples, and writes confined to permitted locations unless explicitly requested by the caller. The matrix uses `--no-manual`, so manual/PDF generation is a separate item to check before a submission decision. CRAN's incoming and platform checks can differ from these CI environments; a green matrix is evidence for the recorded runs, not acceptance by CRAN or suitability for a clinical analysis.
