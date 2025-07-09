#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v Rscript >/dev/null; then
  RSCRIPT="Rscript"
elif [ -x "$script_dir/scripts/Rscript" ]; then
  RSCRIPT="$script_dir/scripts/Rscript"
else
  echo "Rscript not found. Install R to run tests and package installation." >&2
  exit 1
fi

# Install required R packages if missing and run tests
packages=(devtools testthat)
missing_pkgs=()
for pkg in "${packages[@]}"; do
  if ! "$RSCRIPT" -e "quit(status = ifelse(requireNamespace('$pkg', quietly=TRUE), 0, 1))" >/dev/null; then
    missing_pkgs+=("$pkg")
  fi
done

# Install any missing packages from CRAN
if [ ${#missing_pkgs[@]} -gt 0 ]; then
  if [ -n "${SKIP_R_INSTALL:-}" ]; then
    echo "Missing packages: ${missing_pkgs[*]}. SKIP_R_INSTALL is set; skipping installation." >&2
    exit 0
  fi
  pkgs=$(printf '"%s", ' "${missing_pkgs[@]}" | sed 's/, $//')
  "$RSCRIPT" -e "install.packages(c($pkgs), repos='https://packagemanager.rstudio.com/all/latest')"
fi

"$RSCRIPT" scripts/run_tests.R


