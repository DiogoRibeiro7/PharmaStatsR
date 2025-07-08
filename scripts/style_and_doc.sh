#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v Rscript >/dev/null; then
  RSCRIPT="Rscript"
elif [ -x "$script_dir/Rscript" ]; then
  RSCRIPT="$script_dir/Rscript"
else
  echo "Rscript not found. Skipping style and documentation." >&2
  exit 0
fi

need_pkg() {
  "$RSCRIPT" -e "quit(status = ifelse(requireNamespace('$1', quietly=TRUE), 0, 1))" >/dev/null
}

for pkg in styler devtools; do
  if ! need_pkg "$pkg"; then
    echo "Installing missing package $pkg" >&2
    "$RSCRIPT" -e "install.packages('$pkg', repos='https://cloud.r-project.org')"
  fi
done

"$RSCRIPT" -e 'styler::style_pkg()'
"$RSCRIPT" -e 'devtools::document()'
