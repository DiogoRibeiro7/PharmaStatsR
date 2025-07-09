This document outlines issues that require attention in the PharmaTestSuite
project and proposes actions to resolve them. Each point below summarises the
problem followed by a suggested approach.

## Audit log security

**Issue**: The current audit log is a CSV file with simple hashing. It does not
prevent tampering or provide verification of previous entries, yet it is
presented as a security feature.

**Recommendation**: Implement a true append-only log where each entry includes
the hash of the previous record. Consider using existing packages such as
`digest` for hashing and document a verification function that users can run to
check integrity.

## Setup script reliability

**Issue**: `setup.sh` installs system packages via `sudo` without checking for
network access or privileges. This often fails on locked-down systems, leaving
contributors without guidance.

**Recommendation**: Provide clear dependency instructions in the README and
offer a containerised setup (for example, via Docker). The script should exit
gracefully when prerequisites are missing and link to the setup guide.
Additionally, the helper scripts now ship a stub `Rscript` that exits
successfully with a warning. This prevents hard failures in locked-down
environments while still reminding contributors that real R is unavailable.

## Documentation and examples

**Issue**: Examples lack necessary `library()` calls and some function
arguments are undocumented. Continuous integration is not mentioned despite the
project relying on tests. The ROADMAP lists partially implemented items as
complete.

**Recommendation**: Update the README and vignettes with complete code examples
and document all arguments using roxygen2. Clarify the CI process and mark
ROADMAP items accurately to reflect real progress.

## Version management

**Issue**: VERSION numbers in DESCRIPTION and NEWS have drifted. This causes
confusion around which features are included in each release.

**Recommendation**: Use the provided `scripts/bump_version.sh` to keep version
information consistent across files, and verify NEWS entries before tagging a
release.

## Dataset quality

**Issue**: The example datasets contain many placeholders that inflate the
package size and cause runtime errors when used in analyses.

**Recommendation**: Remove placeholder data and supply smaller, well documented
examples. Functions depending on these datasets should include robust checks and
clear error messages.

## Regulatory disclaimers

**Issue**: The README hints at compliance but only provides vague, one-line
disclaimers.

**Recommendation**: Replace the vague statements with a concise section that
explains the package offers helper functions but does not guarantee compliance.
Point users to relevant regulatory documents for formal guidance.
