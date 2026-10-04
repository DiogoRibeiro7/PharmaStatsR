## Release candidate status

Draft for [issue #58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58). Check that issue for the exact final merged commit, source tarball hash, and job links before using these comments for a submission. The maintainer contact, affiliation, and release version still require confirmation.

## Test environments

- macOS, R release, required dependencies and check tools.
- Windows, R release, required dependencies and check tools.
- Ubuntu, R oldrel-1 and devel, required dependencies and check tools.
- Ubuntu, R release, all declared Suggested R packages and Python SciPy 1.17.0, with TinyTeX and HTML Tidy for full manual validation.

## R CMD check results

The current reviewed merged-commit run in #58 built a source tarball and checked it with `R CMD check --as-cran` on Ubuntu R release with all Suggests. It reported **0 errors, 0 warnings, 1 NOTE**. Examples, tests, vignette rebuild, PDF manual, and HTML manual passed. The four required-dependency portability jobs also passed with `--no-manual`.

The single NOTE is **“New submission”** from CRAN incoming feasibility. This is the proposed first submission of PharmaStatsR; no other NOTE was reported in that run. Issue #58 records the latest exact merged SHA, source hash, and matrix results. Because this PR changes package source, check its new merged SHA with the full matrix and update #58 before using these comments for submission; revise this result if the new check differs.

## Additional release review

- Confirm that the public maintainer contact can receive CRAN correspondence and that the recorded affiliation and release version are current.
- Review the final source artifact, license, dependency availability, size, timing, and current CRAN policy against the exact candidate commit in #58.
- No downstream reverse-dependency results are available for a first submission.
