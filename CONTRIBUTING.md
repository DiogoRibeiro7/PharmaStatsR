# Contributing

PharmaStatsR is an R package for statistical demonstrations and research workflows. Contributions to statistical methods should describe assumptions, estimands, input validation, and the interpretation of results. Keep examples based on simulated or public data; do not include patient data.

1. Open an issue for substantial new methods so the interface and validation plan can be reviewed first.
2. Make changes in a short-lived branch and open a pull request into `main`. Do not push directly to `main` or create release tags as part of a feature change.
3. Install R and run `./setup.sh`. This installs the small development test dependencies if needed and fails when they cannot be installed. Run `R CMD check` locally when possible; CI runs it on pull requests.
4. Add `testthat` cases for valid and invalid inputs. For numerical methods, compare with an independent reference or an analytically known result, and make random examples reproducible with a fixed seed.
5. Update roxygen documentation, regenerated `man/` files, `README.md` when applicable, and `NEWS.md`. Note any optional R or Python dependency in `DESCRIPTION`.

The package is for demonstration and research. A passing CI check is not a validation of a method for regulated clinical use.

Documentation changes should update the relevant page under `docs/` and pass `python -m mkdocs build --strict` after installing `requirements-docs.txt`. The documentation workflow verifies the site on pull requests. See [the development guide](https://diogoribeiro7.github.io/PharmaStatsR/development/) for the package and documentation commands.
