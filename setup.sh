#!/usr/bin/env bash
set -euo pipefail

if ! command -v Rscript >/dev/null 2>&1; then
  echo "Rscript not found. Install R before running the package tests." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"
Rscript scripts/run_tests.R
