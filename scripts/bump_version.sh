#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new-version>" >&2
    exit 1
fi

VERSION="$1"

sed -i -e "s/^Version: .*/Version: ${VERSION}/" DESCRIPTION

if grep -q '^version:' CITATION.cff; then
    sed -i -e "s/^version:.*/version: \"${VERSION}\"/" CITATION.cff
fi

if ! grep -q "^## ${VERSION}" NEWS.md; then
    printf '\n## %s\n- Add release notes here.\n' "$VERSION" >> NEWS.md
fi

git add DESCRIPTION CITATION.cff NEWS.md

git commit -m "Bump version to ${VERSION}" && git tag -a "v${VERSION}" -m "Version ${VERSION}"

echo "Bumped version to ${VERSION} and created git tag v${VERSION}."
