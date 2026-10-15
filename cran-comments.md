## Release candidate status

Draft for [issue #58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58),
refreshed on 15 October 2026. Version 0.1.63 remains in development. This evidence
belongs to merged commit `971a37aaf203fad523807c254db930ce588ccbcd`; it is not a
final release decision. Later changes, including README/NEWS changes, require
checks of their own source. Select the final merged commit and replace this
baseline with its actual receipt before submission.

## Test environments

- macOS, R release, required dependencies and check tools.
- Windows, R release, required dependencies and check tools.
- Ubuntu, R oldrel-1 and devel, required dependencies and check tools.
- Ubuntu 24.04.5, R 4.6.1, all declared Suggested R packages and Python SciPy
  1.17.0, with TinyTeX and HTML Tidy for full manual validation.

## R CMD check results

The [merged-commit matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301)
built and checked `PharmaStatsR_0.1.63.tar.gz`. The downloaded source is 438,365
bytes with SHA-256
`0ec1a1447d6b55719ecd8aae122080c742a314a2dedc8d7235026c53c42e705c`.
The [artifact](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38814107301/artifacts/12010840213)
contains a matching commit marker and manifest, check/install logs, and PDF manual.

`R CMD check --as-cran` reported **0 errors, 0 warnings, and 1 NOTE**:

- **New submission**, from CRAN incoming feasibility.

Ordinary examples, the separate `--run-donttest` example pass, tests, vignette
rebuilding, and PDF/HTML manuals all passed. All four required-dependency
portability jobs passed with `--no-manual`. The [release record](docs/release-candidate.md)
contains job links and verification instructions.

## Lengthy example

The full `fit_nlmixr_model()` SAEM help example uses `\donttest{}` following
[CRAN's guidance for lengthy examples](https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples).
The all-Suggests CRAN-style check executed it in the separate `--run-donttest`
pass (50 seconds elapsed, 41 seconds CPU). The original full-data integration
test remains enabled when its backend is installed. Model settings and data
are unchanged. The prior `65bc1be` timing note is absent from this merged run;
this one-note result supersedes that older two-note baseline for this source.

## Additional release review

- Confirm the public maintainer address receives CRAN correspondence, review
  affiliation, and choose the final release version/source.
- Review the final artifact, PDF, every NOTE, license/provenance, dependency
  availability, size/timing, and current CRAN policy in #58. The verifier checks
  evidence consistency; human review and release decisions remain separate.
- No downstream reverse-dependency results are available for a first submission.
