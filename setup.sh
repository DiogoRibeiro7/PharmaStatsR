#!/usr/bin/env bash
set -euo pipefail

# Ensure Rscript is available. If not, instruct the user to install R.
if ! command -v Rscript >/dev/null; then
  echo "Rscript not found. Please install R and rerun this script." >&2
  exit 1
fi

# Install required R packages if missing and run tests
packages=(devtools testthat)
missing_pkgs=()
for pkg in "${packages[@]}"; do
  if ! Rscript -e "quit(status = ifelse(requireNamespace('$pkg', quietly=TRUE), 0, 1))" >/dev/null; then
    missing_pkgs+=("$pkg")
  fi
done

# Install any missing packages from CRAN
if [ ${#missing_pkgs[@]} -gt 0 ]; then
  pkgs=$(printf '"%s", ' "${missing_pkgs[@]}" | sed 's/, $//')
  Rscript -e "install.packages(c($pkgs), repos='https://cloud.r-project.org')"
fi

Rscript - <<'RSCRIPT'
required <- c("devtools", "testthat")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}
devtools::test()
RSCRIPT

