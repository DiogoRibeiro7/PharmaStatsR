This document outlines issues that require attention in the PharmaTestSuite
project and proposes actions to resolve them. Each point below summarises the
problem followed by a suggested approach.

## Audit log security

**Issue**: The audit log now uses SHA256 HMACs chained together, but entries are
still stored in a plain CSV file without secure key management. This remains
easy to tamper with and should not be advertised as a robust security feature.

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
The helper scripts now require a real `Rscript` binary and exit with an error if
it is missing. This prevents tests from being bypassed when R is unavailable.

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

**Issue**: The example datasets previously contained placeholders that inflated
the package size.

**Resolution**: Datasets have been trimmed to small simulated examples and now
include usage examples and documentation. Functions validate inputs and throw
clear errors when data is missing.

## Regulatory disclaimers

**Issue**: The README hints at compliance but only provides vague, one-line
disclaimers.

**Recommendation**: Replace the vague statements with a concise section that
explains the package offers helper functions but does not guarantee compliance.
Point users to relevant regulatory documents for formal guidance.
