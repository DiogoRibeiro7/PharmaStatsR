# Contribution Guidelines

- Run `./setup.sh` before committing. This installs required R packages and executes the package tests.
- Keep the repository style consistent. Use `styler::style_pkg()` on any R changes and document new functions with roxygen2 comments and examples.
- Summarize notable changes in `NEWS.md` and record test results in your PR description.
- When updating the package version, use `scripts/bump_version.sh <new-version>` so `DESCRIPTION` and `CITATION.cff` stay in sync.
- Ensure `git status` is clean after running tests.
