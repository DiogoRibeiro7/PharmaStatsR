"""Exercise artifact failures with small, synthetic source/check bundles."""

import hashlib
import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "verify_release_artifact.py"
SPEC = importlib.util.spec_from_file_location("verify_release_artifact", SCRIPT)
VERIFIER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFIER)
COMMIT = "a" * 40

# Keep the fixture's required pass list independent of the verifier constant.
LOG = """* using option ‘--as-cran’
* this is package ‘PharmaStatsR’ version ‘0.1.63’
* checking CRAN incoming feasibility ... [2s/3s] NOTE
Maintainer: ‘Example <example@example.org>’

New submission
* checking package dependencies ... OK
* checking installed package size ... OK
* checking DESCRIPTION meta-information ... OK
* checking examples ... [3s/4s] OK
* checking examples with --run-donttest ... [40s/50s] OK
* checking tests ... [30s/35s] OK
  Running ‘testthat.R’
* checking package vignettes ... OK
* checking re-building of vignette outputs ... OK
* checking PDF version of manual ... OK
* checking HTML version of manual ... OK
* DONE
Status: 1 NOTE
"""


class ArtifactTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.files = {name: b"fixture\n" for name in VERIFIER.REQUIRED_FILES}
        self.files["DESCRIPTION"] = b"Package: PharmaStatsR\nVersion: 0.1.63\n"
        self.tarball = self.root / "PharmaStatsR_0.1.63.tar.gz"
        self.write_archive()
        (self.root / "candidate-commit.txt").write_text(COMMIT + "\n", encoding="utf-8")
        self.check_dir = self.root / "PharmaStatsR.Rcheck"
        self.check_dir.mkdir()
        self.log = self.check_dir / "00check.log"
        self.log.write_text(LOG, encoding="utf-8")
        (self.check_dir / "00install.out").write_text("* DONE (PharmaStatsR)\n")
        (self.check_dir / "PharmaStatsR-manual.pdf").write_bytes(b"%PDF-1.4\nfixture")

    def write_archive(self, extra=None):
        names = []
        with tarfile.open(self.tarball, "w:gz") as archive:
            for name, content in self.files.items():
                member = tarfile.TarInfo("PharmaStatsR/" + name)
                member.size = len(content)
                archive.addfile(member, io.BytesIO(content))
                names.append(member.name)
            if extra:
                archive.addfile(extra)
                names.append(extra.name)
        (self.root / "candidate-contents.txt").write_text("\n".join(names) + "\n")
        digest = hashlib.sha256(self.tarball.read_bytes()).hexdigest()
        (self.root / "candidate-sha256.txt").write_text(f"{digest}  ./{self.tarball.name}\n")

    def verify(self):
        return VERIFIER.verify(self.root, COMMIT)

    def test_valid_receipt_preserves_note_for_review(self):
        receipt = self.verify()
        self.assertEqual(receipt["commit"], COMMIT)
        self.assertEqual(receipt["version"], "0.1.63")
        self.assertEqual(receipt["source_bytes"], self.tarball.stat().st_size)
        self.assertEqual(len(receipt["notes"]), 1)
        self.assertIn("New submission", receipt["notes"][0])

    def test_commit_mismatch(self):
        with self.assertRaisesRegex(ValueError, "Commit marker"):
            VERIFIER.verify(self.root, "b" * 40)

    def test_changed_tarball_bytes(self):
        with self.tarball.open("ab") as stream:
            stream.write(b"changed")
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            self.verify()

    def test_manifest_mismatch(self):
        (self.root / "candidate-contents.txt").write_text("PharmaStatsR/DESCRIPTION\n")
        with self.assertRaisesRegex(ValueError, "Manifest"):
            self.verify()

    def test_missing_imported_resource(self):
        del self.files["inst/NOTICE-pharmoCovR"]
        self.write_archive()
        with self.assertRaisesRegex(ValueError, "Missing source files"):
            self.verify()

    def test_development_content(self):
        self.files["docs/unwanted.md"] = b"development only"
        self.write_archive()
        with self.assertRaisesRegex(ValueError, "Development-only"):
            self.verify()

    def test_unsafe_path_or_link(self):
        for name, kind in [("PharmaStatsR/../outside", tarfile.REGTYPE),
                           ("/outside", tarfile.REGTYPE),
                           ("PharmaStatsR/link", tarfile.SYMTYPE)]:
            with self.subTest(name=name):
                member = tarfile.TarInfo(name)
                member.type = kind
                member.linkname = "outside"
                self.write_archive(member)
                with self.assertRaisesRegex(ValueError, "Invalid source path|member type"):
                    self.verify()

    def test_package_version_mismatch(self):
        self.files["DESCRIPTION"] = b"Package: PharmaStatsR\nVersion: 0.1.64\n"
        self.write_archive()
        with self.assertRaisesRegex(ValueError, "version differ"):
            self.verify()

    def test_missing_or_failed_check_passes(self):
        for name in ("examples", "examples with --run-donttest", "tests",
                     "re-building of vignette outputs", "PDF version of manual"):
            with self.subTest(name=name):
                self.log.write_text(LOG.replace(f"* checking {name} ...", "* skipped ..."),
                                    encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "Missing or unsuccessful check"):
                    self.verify()

    def test_failed_incomplete_or_inconsistent_log(self):
        for log in (LOG.replace("Status: 1 NOTE", "Status: 1 WARNING, 1 NOTE"),
                    LOG.replace("* DONE\n", ""),
                    LOG.replace("Status: 1 NOTE", "Status: 2 NOTEs"),
                    LOG.replace("version ‘0.1.63’", "version ‘0.1.64’"),
                    LOG.replace("--as-cran", "--no-manual")):
            with self.subTest(log=log):
                self.log.write_text(log, encoding="utf-8")
                with self.assertRaises(ValueError):
                    self.verify()

    def test_additional_note_is_reported(self):
        note = "* checking examples ... NOTE\nExample timing requires review"
        self.log.write_text(LOG.replace("* checking examples ... [3s/4s] OK", note)
                           .replace("Status: 1 NOTE", "Status: 2 NOTEs"), encoding="utf-8")
        self.assertIn("Example timing requires review", self.verify()["notes"][1])

    def test_no_notes_and_ascii_log(self):
        start = LOG.index("* checking CRAN incoming feasibility")
        end = LOG.index("* checking package dependencies")
        log = (LOG[:start] + LOG[end:]).replace("Status: 1 NOTE", "Status: OK")
        self.log.write_text(log.replace("‘", "'").replace("’", "'"), encoding="utf-8")
        self.assertEqual(self.verify()["notes"], [])

    def test_missing_manual_or_install_log(self):
        (self.check_dir / "PharmaStatsR-manual.pdf").write_bytes(b"not a PDF")
        with self.assertRaisesRegex(ValueError, "PDF manual"):
            self.verify()
        (self.check_dir / "00install.out").write_text("installation failed")
        with self.assertRaisesRegex(ValueError, "installation evidence"):
            self.verify()

    def test_cli_failure_returns_nonzero(self):
        result = subprocess.run([sys.executable, str(SCRIPT), str(self.root),
                                 "--commit", "bad"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("Artifact verification failed", result.stderr)


if __name__ == "__main__":
    unittest.main()
