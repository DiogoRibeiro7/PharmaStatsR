"""Verify a downloaded PharmaStatsR source/check artifact without extracting it.

Uses only the Python standard library. Successful verification reports all NOTEs;
it does not approve them or authorize a release. The commit is supplied by the
reviewer from the trusted Actions run, independently of the artifact's marker.
"""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import sys
import tarfile


PACKAGE = "PharmaStatsR"
REQUIRED_FILES = {
    "DESCRIPTION", "NAMESPACE", "LICENSE", "NEWS.md", "README.md",
    "inst/CITATION", "inst/NOTICE-pharmoCovR",
    "inst/templates/covariate-report.Rmd",
    "inst/shiny/covariate_diagnostics_app.R", "data/pharmo_example.rda",
    "R/covariate_fit_nlmixr.R", "man/fit_nlmixr_model.Rd",
    "tests/testthat.R", "tests/testthat/test-covariate-migration.R",
    "tests/testthat/test-covariate-nlmixr-helpers.R",
    "vignettes/pharma_workflow.Rmd", "vignettes/covariate-advanced.Rmd",
    "vignettes/covariate-data-preparation.Rmd",
    "vignettes/covariate-diagnostics.Rmd",
    "vignettes/covariate-full-workflow.Rmd", "vignettes/covariate-quickstart.Rmd",
}
EXCLUDED_ROOTS = {".github", "docs", "data-raw", "scripts"}
REQUIRED_CHECKS = (
    "package dependencies", "installed package size", "DESCRIPTION meta-information",
    "examples", "examples with --run-donttest", "tests", "package vignettes",
    "re-building of vignette outputs", "PDF version of manual", "HTML version of manual",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_text(path):
    return path.read_text(encoding="utf-8")


def check_log(text, version):
    # R uses typographic quotes in UTF-8 logs and ASCII quotes in some locales.
    text = text.translate(str.maketrans({"‘": "'", "’": "'"}))
    require("* using option '--as-cran'" in text, "Missing --as-cran evidence")
    require(f"* this is package '{PACKAGE}' version '{version}'" in text,
            "Check log package/version does not match the source")
    require(re.search(r"^\* DONE\s*$", text, re.MULTILINE), "Incomplete check log")
    summaries = re.findall(r"^Status: (.+)$", text, re.MULTILINE)
    require(len(summaries) == 1, "Expected one final check status")
    summary = summaries[0].strip()
    require(summary == "OK" or re.fullmatch(r"[1-9][0-9]* NOTEs?", summary),
            f"Check did not finish with only OK/NOTEs: {summary}")
    require(not re.search(r"^\* checking .*\.\.\. .*\b(?:ERROR|WARNING)\b",
                          text, re.MULTILINE), "Check log contains errors or warnings")
    for name in REQUIRED_CHECKS:
        matches = re.findall(r"^\* checking " + re.escape(name) + r" \.\.\. (.+)$",
                             text, re.MULTILINE)
        require(len(matches) == 1 and re.fullmatch(r"(?:\[[^\]\n]+\] )?(?:OK|NOTE)", matches[0]),
                f"Missing or unsuccessful check: {name}")
    notes = []
    for block in re.split(r"(?m)(?=^\* )", text):
        if re.match(r"\* checking .*\.\.\. (?:\[[^\]\n]+\] )?NOTE\s*\n", block):
            notes.append(block.strip())
    expected = 0 if summary == "OK" else int(summary.split()[0])
    require(len(notes) == expected, "NOTE blocks do not match the final status")
    return notes


def verify(directory, commit):
    directory = Path(directory)
    require(re.fullmatch(r"[0-9a-f]{40}", commit), "Supply the full lowercase commit SHA")
    require(read_text(directory / "candidate-commit.txt").strip() == commit,
            "Commit marker does not match the expected commit")
    tarballs = list(directory.glob(f"{PACKAGE}_*.tar.gz"))
    require(len(tarballs) == 1, "Expected exactly one PharmaStatsR source tarball")
    tarball = tarballs[0]
    digest = hashlib.sha256(tarball.read_bytes()).hexdigest()
    checksum = re.fullmatch(r"([0-9a-f]{64}) [ *](?:\./)?([^/\\\r\n]+)\s*",
                            read_text(directory / "candidate-sha256.txt"))
    require(checksum is not None and checksum[1] == digest and checksum[2] == tarball.name,
            "SHA-256 record does not match the tarball bytes/name")

    with tarfile.open(tarball, "r:gz") as archive:
        members = archive.getmembers()
        names = [member.name.rstrip("/") for member in members]
        require(len(names) == len(set(names)), "Duplicate paths in the source tarball")
        files = set()
        for member in members:
            path = PurePosixPath(member.name)
            require(path.parts and not path.is_absolute() and ".." not in path.parts
                    and "\\" not in member.name and path.parts[0] == PACKAGE,
                    f"Invalid source path: {member.name}")
            require(member.isfile() or member.isdir(),
                    f"Unexpected archive member type: {member.name}")
            require(len(path.parts) < 2 or path.parts[1] not in EXCLUDED_ROOTS,
                    f"Development-only content in source: {member.name}")
            if member.isfile():
                require(member.size > 0, f"Empty source file: {member.name}")
                files.add(str(path.relative_to(PACKAGE)))
        require(REQUIRED_FILES <= files,
                f"Missing source files: {sorted(REQUIRED_FILES - files)}")
        manifest = [line.rstrip("/") for line in
                    read_text(directory / "candidate-contents.txt").splitlines()]
        require(Counter(manifest) == Counter(names), "Manifest does not match the tarball")
        description = archive.extractfile(f"{PACKAGE}/DESCRIPTION").read().decode("utf-8")
        packages = re.findall(r"^Package: (.+)$", description, re.MULTILINE)
        versions = re.findall(r"^Version: (.+)$", description, re.MULTILINE)
        require(packages == [PACKAGE] and len(versions) == 1, "Invalid DESCRIPTION identity")
        version = versions[0].strip()
        require(tarball.name == f"{PACKAGE}_{version}.tar.gz",
                "Tarball filename and DESCRIPTION version differ")

    check_dir = directory / f"{PACKAGE}.Rcheck"
    notes = check_log(read_text(check_dir / "00check.log"), version)
    require(f"* DONE ({PACKAGE})" in read_text(check_dir / "00install.out"),
            "Missing successful installation evidence")
    manual = check_dir / f"{PACKAGE}-manual.pdf"
    require(manual.read_bytes().startswith(b"%PDF-"), "Missing or invalid PDF manual")
    return {
        "commit": commit, "package": PACKAGE, "version": version,
        "tarball": tarball.name, "source_bytes": tarball.stat().st_size,
        "archive_entries": len(members), "sha256": digest,
        "errors": 0, "warnings": 0, "notes": notes,
        "required_checks": list(REQUIRED_CHECKS),
        "release_decision": "Requires review of NOTEs, provenance, and maintainer choices",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path, help="Downloaded artifact directory")
    parser.add_argument("--commit", required=True, help="Expected full Actions checkout SHA")
    args = parser.parse_args()
    try:
        receipt = verify(args.directory, args.commit)
    except (OSError, ValueError, tarfile.TarError) as error:
        print(f"Artifact verification failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps(receipt, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
