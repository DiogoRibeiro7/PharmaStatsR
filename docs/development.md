# Development

Contributions are reviewed through a branch and pull request to `main`. For statistical changes, describe the estimand, assumptions, input checks, and expected interpretation. Use simulated or public example data.

## Package checks

Install R, then from the repository root run:

```sh
./setup.sh
```

The script checks namespace-qualified calls against `DESCRIPTION`, installs the development test dependencies if necessary, and runs the `testthat` suite. Use `SKIP_R_INSTALL=1 ./setup.sh` to use an existing R library; missing packages will cause failure. For R source changes, run `scripts/style_and_doc.sh` and commit the regenerated `man/` pages. Run an R CMD check locally when possible. All Rd pages in `man/` are generated from roxygen comments in `R/`. The routine PR workflow reruns roxygen2, fails if `NAMESPACE` or `man/` differs from the committed files or a hand-maintained Rd page is added, and uploads the generated diff as `documentation-drift` when available.

The [dependency audit](dependency-audit.md) maps `Imports`, `Suggests`, dynamic runtime checks, and the remaining optional-backend review in #53.

| Workflow | Trigger | Environment and dependencies |
| --- | --- | --- |
| [R-CMD-check](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-CMD-check.yaml) | Each PR and push to `main`, and manual dispatch | Ubuntu R release; hard dependencies, test/vignette tools, and the listed optional backends. SciPy is installed in Python 3.12. Other Suggested packages may be absent (`_R_CHECK_FORCE_SUGGESTS_=false`). |
| [R validation matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/R-validation-matrix.yaml), portability | Mondays at 05:17 UTC, manual dispatch, and PRs that change the matrix workflow | macOS/Windows R release and Ubuntu R oldrel-1/devel; hard dependencies and test/vignette tools. Optional integrations may skip when their backends are absent. |
| R validation matrix, optional backends | Same matrix triggers | Ubuntu R release with all `Imports` and `Suggests` installed (`_R_CHECK_FORCE_SUGGESTS_=true`), plus SciPy on Python 3.12. This installs the larger Stan toolchain, so the workflow has a 90-minute job limit. |

`setup-r-dependencies@v2` caches installed packages between compatible runs; its job log records package versions. The Actions run page ties each result to a commit SHA and keeps step logs. Failed checks upload the `check/` directory when it exists. Use **Run workflow** on the matrix workflow and select the candidate branch before reviewing a release; record the resulting SHA and job results in issue #54 or the release candidate issue #58. Scheduled runs use the default branch.

Both workflows use `check-r-package@v2` with `R CMD check --no-manual --as-cran` and fail on warnings. The matrix states these arguments explicitly; the routine check uses the action defaults. The action disables the CRAN incoming check by default, and neither workflow establishes the remaining release-candidate evidence in [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58). A green matrix shows that the checked paths work in those environments; it is not a statistical validation or a CRAN submission decision.

Use a platform-specific skip only for a feature that is genuinely unavailable on that platform, with a focused reason and issue link. A missing optional backend may use `skip_if_not_installed()`, but it must have a deterministic missing-package test. When a check appears flaky, rerun it once on the same SHA, preserve the logs, and investigate the cause before removing or weakening the assertion.

For numeric methods, include tests against an independently calculated or known result, boundary and invalid-input cases, and reproducible random examples.

## Documentation site

Python 3 is needed to build the site:

```sh
python -m pip install -r requirements-docs.txt
python -m mkdocs build --strict
python -m mkdocs serve
```

The site source is in `docs/` and `mkdocs.yml`. The [Documentation workflow](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/workflows/docs.yml) runs a strict MkDocs build for documentation-related pull requests. After a relevant change reaches `main`, its build job uploads the site and a separate deploy job publishes it to [GitHub Pages](https://diogoribeiro7.github.io/PharmaStatsR/). Repository **Settings → Pages** must use **GitHub Actions** as the source. The workflow's build success alone does not confirm a successful deployment; check the `deploy` job and the site URL after merging.

Read [CONTRIBUTING.md](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/CONTRIBUTING.md) and [SECURITY.md](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/SECURITY.md) before opening a public issue. Update `NEWS.md` for notable changes and include test results in the pull request.
