# Contribution Guidelines

- Run `./setup.sh` before committing. This installs required R packages and executes the package tests.
- The environment should have R installed. If `Rscript` is missing, run:
  `sudo apt-get update && sudo apt-get install -y r-base`.
- Keep the repository style consistent. Use `styler::style_pkg()` on any R changes and document new functions with roxygen2 comments and examples.
- Summarize notable changes in `NEWS.md` and record test results in your PR description.
- When updating the package version, use `scripts/bump_version.sh <new-version>` so `DESCRIPTION` and `CITATION.cff` stay in sync.
- Ensure `git status` is clean after running tests.
- Edit the working checkout directly. Keep task scripts, check logs, builds,
  and downloaded CI evidence under `.git/codex-work/` (resolve the Git
  directory first), not in persistent folders under the system Temp directory.
  Use ignored `build/codex-runtime/` for disposable R runtime files when tools
  cannot handle hidden paths. Run package checks on a clean source snapshot
  under Git metadata, with runtime files outside that snapshot, to avoid
  recursive copying during `R CMD build`.
  Reuse a persistent R library; do not install reusable dependencies into Temp.
  Retain needed check records and remove verified disposable artifacts when
  the task is complete.
