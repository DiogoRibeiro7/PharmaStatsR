This document summarises outstanding issues in the PharmaStatsR project and proposes concrete actions for each topic.

## Audit log security
Current Status: The audit log uses SHA256 HMACs chained together but relies on a CSV file with no key management.
Action items:
- Investigate append-only log formats and link entries using the `digest` package.
- Provide a verification function that recalculates hashes.
- Document the minimal security guarantees clearly in the README.

## Setup script reliability
Current Status: `setup.sh` installs packages via `sudo` and assumes network access.
Action items:
- Add prerequisite instructions in the README.
- Detect missing privileges or offline environments and exit with guidance.
- Offer a Docker-based setup for consistent environments.
- Ensure scripts halt if R or dependencies are unavailable.

## Documentation and examples
Current Status: Examples sometimes omit `library()` calls and not all parameters are documented. Continuous integration is mentioned only briefly.
Action items:
- Include `library(PharmaStatsR)` in every example.
- Document all function arguments using roxygen2 with runnable examples.
- Explain the GitHub Actions workflow in the README.
- Mark unimplemented ROADMAP items as planned or in progress rather than complete.

## Version management
Current Status: Version numbers occasionally drift between DESCRIPTION and NEWS.
Action items:
- Always use `scripts/bump_version.sh` when changing the version.
- Verify NEWS entries reflect the implemented features before tagging a release.

## Dataset quality
Current Status: Early datasets were placeholders that inflated the package size.
Action items:
- Keep datasets small and simulated.
- Document usage examples for each dataset.
- Validate dataset structure in tests.

## Regulatory disclaimers
Current Status: The README previously contained vague statements about compliance.
Action items:
- Provide a concise disclaimer referencing ICH E9(R1) and FDA guidance.
- Clarify that PharmaStatsR facilitates analysis but does not ensure compliance.

## Continuous integration
Current Status: Tests may be skipped when dependencies are missing.
Action items:
- Configure CI to fail fast if any package installation fails.
- Run `R CMD check` on every commit to ensure a clean test environment.
