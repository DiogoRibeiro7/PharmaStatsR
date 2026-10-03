"""Require one supported-level inventory entry for every NAMESPACE export."""

from collections import Counter
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "docs" / "method-inventory.md"
LEVELS = {"Stable", "Experimental", "Example-only", "Deprecation candidate"}
EXPORT = re.compile(r"^export\(([^)]+)\)$")
ROW = re.compile(r"^\| \[`([^`]+)`\]")


def check() -> None:
    namespace = [
        match.group(1).strip('"')
        for line in (ROOT / "NAMESPACE").read_text().splitlines()
        if (match := EXPORT.fullmatch(line))
    ]
    rows = {}
    for line in INVENTORY.read_text().splitlines():
        match = ROW.match(line)
        if not match:
            continue
        columns = [column.strip() for column in line.strip().strip("|").split("|")]
        name = match.group(1)
        rows.setdefault(name, []).append(columns[-1] if len(columns) == 6 else "malformed")

    counts = Counter(namespace)
    failures = []
    if duplicates := sorted(name for name, count in counts.items() if count != 1):
        failures.append(f"Duplicate NAMESPACE exports: {duplicates}")
    if missing := sorted(set(namespace) - rows.keys()):
        failures.append(f"Exports missing from inventory: {missing}")
    if extra := sorted(rows.keys() - set(namespace)):
        failures.append(f"Inventory entries absent from NAMESPACE: {extra}")
    if duplicates := sorted(name for name, levels in rows.items() if len(levels) != 1):
        failures.append(f"Duplicate inventory entries: {duplicates}")
    if invalid := sorted((name, levels) for name, levels in rows.items()
                         if any(level not in LEVELS for level in levels)):
        failures.append(f"Missing or invalid support levels: {invalid}")
    if failures:
        raise ValueError("\n".join(failures))
    levels = Counter(values[0] for values in rows.values())
    print(f"API support inventory: {len(rows)} exports, " +
          ", ".join(f"{level.lower()}={levels[level]}" for level in sorted(LEVELS)))


if __name__ == "__main__":
    try:
        check()
    except ValueError as error:
        print(error, file=sys.stderr)
        sys.exit(1)
