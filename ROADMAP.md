# Roadmap

This file outlines planned milestones for PharmaTestR. The timelines are approximate and may shift as the project evolves.

## Short Term (0-3 months)
- Finalize the package skeleton with proper documentation and examples.
- Implement wrappers for common statistical tests: t-test, chi-square, ANOVA, and logistic regression.
- Provide a small example dataset (`pharma_sample`) for demonstration purposes.
- Write unit tests using **testthat** for each exported function.
- Set up continuous integration (GitHub Actions) to run `R CMD check` on push and pull requests.

## Medium Term (3-6 months)
- Incorporate de-identified pharmaceutical datasets for realistic examples.
- Add regulatory compliance helpers (e.g., checks for ICH guideline adherence).
- Expand the test suite with survival analysis functions and repeated measures designs.
- Create vignettes that walk through typical pharmaceutical workflows from data cleaning to reporting.
- Gather user feedback and refine function interfaces and documentation accordingly.

## Long Term (6-12 months)
- Prepare the package for CRAN submission: resolve all `R CMD check` warnings/notes and polish metadata.
- Build a pkgdown site for easy navigation of documentation and tutorials.
- Provide example Shiny apps for interactive visualization of trial results.
- Ensure cross-platform compatibility (Windows, macOS, Linux) and add installation instructions for each.
- Continue expanding functionality and datasets in response to community contributions.
