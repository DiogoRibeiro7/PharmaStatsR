## Release candidate status

Draft for [issue #58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58), refreshed on 15 October 2026 after the covariate consolidation. Version 0.1.63 remains a development version for this record. The evidence below is tied to merged commit `65bc1be17fc150e1af42eab6c2b6b33d7f167046`, not a final release decision. The 7 October `7057b1b` candidate is superseded for the current source. Select and recheck the final merged commit before using these comments for submission.

## Test environments

- macOS, R release, required dependencies and check tools.
- Windows, R release, required dependencies and check tools.
- Ubuntu, R oldrel-1 and devel, required dependencies and check tools.
- Ubuntu, R release, all declared Suggested R packages and Python SciPy 1.17.0, with TinyTeX and HTML Tidy for full manual validation.

## R CMD check results

The [merged-commit matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182) built and checked `PharmaStatsR_0.1.63.tar.gz` on Ubuntu 24.04.5 / R 4.6.1 with all Suggests. Its SHA-256 is `b00c781b2ebbc79f1635959190df7c9aa5fd8fd9cda5300c4351a51b44e153b4`. `R CMD check --as-cran` reported **0 errors, 0 warnings, 2 notes**. Examples, tests, vignette rebuilding, PDF manual, and HTML manual passed. All four required-dependency portability jobs passed with `--no-manual`. The [release evidence](docs/release-candidate.md) records artifact inspection and job links.

The notes are:

- **New submission**, from CRAN incoming feasibility.
- **Example runtime**: `fit_nlmixr_model()` used 9 seconds elapsed and 13.166 seconds CPU in this run. Its optional SAEM example needs runtime review or reduction before submission; no exception has been accepted by this record.

## Lengthy-example follow-up

The full `fit_nlmixr_model()` help example is now marked with `\donttest{}` in
accordance with [CRAN's guidance for lengthy examples](https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples).
`R CMD check --as-cran` still executes it in the separate `--run-donttest` pass.
The original full-data integration test remains enabled when the backend is
installed; the model, estimation defaults, and example data are unchanged.

The two-note result above describes the historical `65bc1be` baseline. Run the
full matrix on the final merged SHA, verify successful ordinary and
`--run-donttest` example passes, inspect that artifact, and replace this baseline
evidence with its actual notes before submission. A matching version number
does not mean two tarballs are identical.

## Additional release review

- Confirm the designated public maintainer address receives CRAN correspondence, review the recorded affiliation, and decide the final release version.
- Review the final source artifact, license, dependency availability, size, timing, and current CRAN policy against the exact candidate commit in #58.
- No downstream reverse-dependency results are available for a first submission.
