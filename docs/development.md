# Development

Contributions are reviewed through a branch and pull request to `main`. For statistical changes, describe the estimand, assumptions, input checks, and expected interpretation. Use simulated or public example data.

## Package checks

Install R, then from the repository root run:

```sh
./setup.sh
```

The script checks qualified calls and literal optional-package guards against `DESCRIPTION`, installs the development test dependencies if necessary, and runs the `testthat` suite. Use `SKIP_R_INSTALL=1 ./setup.sh` to use an existing R library; missing packages will cause failure. For R source changes, run `scripts/style_and_doc.sh` and commit the regenerated `man/` pages. Run an R CMD check locally when possible. All Rd pages in `man/` are generated from roxygen comments in `R/`. The routine PR workflow reruns roxygen2, fails if `NAMESPACE` or `man/` differs from the committed files or a hand-maintained Rd page is added, and uploads the generated diff as `documentation-drift` when available.

The [dependency audit](dependency-audit.md) maps `Imports`, `Suggests`, runtime guards, and the available and missing-path tests for each optional entry point. Issue #53 closed after the [five-job candidate matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37120561275) passed on commit `d06f614`; #58 still requires release-candidate evidence on its own exact commit.

| Workflow | Trigger | Environment and dependencies |
| --- | --- | --- |
| [R-CMD-check](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml), required dependencies | Each PR and push to `main`, and manual dispatch | Ubuntu R release; hard dependencies plus `testthat`, `knitr`, `rmarkdown`, and `rcmdcheck` for checking. No Suggested modeling or reporting backend is installed explicitly. `_R_CHECK_FORCE_SUGGESTS_=false` lets optional installed-path tests skip. |
| R-CMD-check, selected backends | Same triggers | Ubuntu R release; hard dependencies, test/vignette tools, and the listed optional backends. SciPy is installed in Python 3.12. Other Suggested packages may be absent (`_R_CHECK_FORCE_SUGGESTS_=false`). |
| [R validation matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-validation-matrix.yaml), portability | Mondays at 05:17 UTC, manual dispatch, and PRs or pushes to `main` that change package source (including README), candidate comments, or the matrix workflow | macOS/Windows R release and Ubuntu R oldrel-1/devel; hard dependencies and test/vignette tools. Optional integrations may skip when their backends are absent. PRs check out their head SHA. |
| R validation matrix, optional backends | Same matrix triggers | Ubuntu R release with all `Imports` and `Suggests` installed (`_R_CHECK_FORCE_SUGGESTS_=true`), SciPy on Python 3.12, TinyTeX, and HTML Tidy. The job builds and inspects a source tarball, checks it with `R CMD check --as-cran` including PDF/HTML manual validation, and uploads the source/hash/log and generated PDF evidence. It has a 90-minute limit. |

The matrix audits source dependency declarations on every platform. `setup-r-dependencies@v2` caches installed packages between compatible runs; its job log and the all-Suggests verification step record package versions. The Actions run page ties each result to a commit SHA and keeps step logs. Failed checks upload the `check/` directory when it exists. Use **Run workflow** on the matrix workflow and select the candidate branch before reviewing a release; record the resulting SHA and job results in issue #54 or the release candidate issue #58. Scheduled runs use the default branch.

The all-Suggests job tests `scripts/verify_release_artifact.py`, then runs it on
the built source and check output. It retains `candidate-verification.json`
alongside the tarball, checksum, manifest, commit marker, logs, and manual. The
verifier checks artifact consistency and requires the ordinary and
`--run-donttest` example passes, tests, vignette rebuilding, and PDF/HTML manual
checks to finish with OK or a reported NOTE. Errors, warnings, missing evidence,
and mismatched records fail verification. Every NOTE remains visible for review;
the script does not approve a release. Changes to the verifier or its tests also
trigger the full matrix. See [download and verification instructions](release-candidate.md#verify-a-downloaded-artifact).

The routine workflow and the matrix portability jobs use `check-r-package@v2` with `R CMD check --no-manual --as-cran`; the action disables the CRAN incoming check by default. The matrix all-Suggests job invokes `R CMD build` and `R CMD check --as-cran` directly on the built tarball, including its manual and incoming check. Its check may therefore expose findings that routine jobs did not. The [release candidate gate](release-candidate.md) requires reviewing all results on a single final SHA, including the uploaded tarball, manual, and any NOTEs. A green matrix is not statistical validation or a CRAN submission decision.

Use a platform-specific skip only for a feature that is genuinely unavailable on that platform, with a focused reason and issue link. A missing optional backend may use `skip_if_not_installed()`, but it must have a deterministic missing-package test. When a check appears flaky, rerun it once on the same SHA, preserve the logs, and investigate the cause before removing or weakening the assertion.

For numeric methods, include tests against an independently calculated or known result, boundary and invalid-input cases, and reproducible random examples.

## Diagnostics browser checks

The [Diagnostics browser checks workflow](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/diagnostics-browser.yml)
runs on each PR, push to main, and manual dispatch. It loads the package source
with `pkgload`, runs a local Shiny server bound to `127.0.0.1`, and exercises the
[diagnostics workflow](diagnostics-app.md) with Chromium, Playwright and axe-core.
It uses synthetic CSVs and makes no external data uploads. The Node dependencies
are locked in `scripts/browser/package-lock.json` and are excluded from the R
source package. No new runtime R package is required.

With R and Node 24 on PATH, install the package's hard dependencies plus `pkgload`
and current `shiny`, then run:

```sh
cd scripts/browser
npm ci --ignore-scripts
npx playwright install --with-deps chromium
npm test
```

Port 3877 must be free. The runner starts and stops its own server and fails if
that port is already occupied. To use an installed Chrome locally, set the
environment variable `PLAYWRIGHT_CHANNEL=chrome` before `npm test`; CI uses the
Chromium version bundled with the locked Playwright release. On PowerShell, use
`$env:PLAYWRIGHT_CHANNEL = "chrome"`.

The HTML report includes full axe JSON for every audited state, including
incomplete checks that require manual review. Screenshots of the binned summary
and narrow layout are retained on success, and traces/screenshots on failure.
CI uploads `diagnostics-browser-evidence` even when tests fail. Tests fail on any
automated axe violation; no rules are disabled. This is scoped automated evidence,
not a WCAG certification or a substitute for assistive-technology testing.

## Documentation site

Python 3 is needed to build the site:

```sh
python -m pip install -r requirements-docs.txt
python -m mkdocs build --strict
python -m mkdocs serve
```

The site source is in `docs/` and `mkdocs.yml`. The [Documentation workflow](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/docs.yml) runs a strict MkDocs build for documentation-related pull requests. After a relevant change reaches `main`, its build job uploads the site and a separate deploy job publishes it to [GitHub Pages](https://diogoribeiro7.github.io/PharmaStatsR/). Repository **Settings → Pages** must use **GitHub Actions** as the source. The workflow's build success alone does not confirm a successful deployment; check the `deploy` job and the site URL after merging.

Read [CONTRIBUTING.md](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/CONTRIBUTING.md) and [SECURITY.md](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/SECURITY.md) before opening a public issue. Update `NEWS.md` for notable changes and include test results in the pull request.
