# Development

Contributions are reviewed through a branch and pull request to `main`. For statistical changes, describe the estimand, assumptions, input checks, and expected interpretation. Use simulated or public example data.

## Package checks

Install R, then from the repository root run:

```sh
./setup.sh
```

The script installs the development test dependencies if necessary and runs the `testthat` suite. Use `SKIP_R_INSTALL=1 ./setup.sh` to use an existing R library; missing packages will cause failure. For R source changes, run `scripts/style_and_doc.sh` and commit the regenerated `man/` pages. Run an R CMD check locally when possible. CI performs the package check on pull requests with required dependencies; optional backends need separate checks when installed.

For numeric methods, include tests against an independently calculated or known result, boundary and invalid-input cases, and reproducible random examples.

## Documentation site

Python 3 is needed to build the site:

```sh
python -m pip install -r requirements-docs.txt
python -m mkdocs build --strict
python -m mkdocs serve
```

The site source is in `docs/` and `mkdocs.yml`. CI checks links and configuration by running a strict build on pull requests; the publishing workflow deploys on pushes to `main` after GitHub Pages is set to **GitHub Actions** as its source.

Read [CONTRIBUTING.md](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/CONTRIBUTING.md) and [SECURITY.md](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/SECURITY.md) before opening a public issue. Update `NEWS.md` for notable changes and include test results in the pull request.
