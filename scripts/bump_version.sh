#!/bin/bash
# bump_version.sh
#
# Update package version metadata and create a Git tag for the release.
# The script expects the new version number as its only argument.
# It updates DESCRIPTION and CITATION.cff, appends a NEWS entry, commits the
# changes and tags the commit.

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new-version>" >&2
    exit 1
fi

VERSION="$1"

# Update DESCRIPTION with the new version number
sed -i -e "s/^Version: .*/Version: ${VERSION}/" DESCRIPTION

if grep -q '^version:' CITATION.cff; then
    # Keep CITATION.cff in sync with DESCRIPTION
    sed -i -e "s/^version:.*/version: \"${VERSION}\"/" CITATION.cff
fi

if ! grep -q "^## ${VERSION}" NEWS.md; then
    # Add a placeholder section to NEWS.md if one doesn't exist
    printf '\n## %s\n- Add release notes here.\n' "$VERSION" >> NEWS.md
fi

git add DESCRIPTION CITATION.cff NEWS.md

# Commit the changes and create a tag matching the version number
git commit -m "Bump version to ${VERSION}" && git tag -a "v${VERSION}" -m "Version ${VERSION}"

echo "Bumped version to ${VERSION} and created git tag v${VERSION}."
