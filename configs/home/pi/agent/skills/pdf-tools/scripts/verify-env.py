#!/usr/bin/env python3
"""Verify that every PDF tool this skill needs is callable.

Checks, in order:
  1. CLI binaries resolve on PATH and report a version
  2. Python modules import and report a version
  3. End-to-end smoke test: PDF -> PNG (pdftoppm) -> OCR (tesseract)

Only the binaries below are expected; pdf2image and pytesseract are deliberately
absent because they are thin wrappers around these same executables.

Usage:
    python3 verify-env.py            # full check
    python3 verify-env.py --no-smoke # binaries and imports only
    python3 verify-env.py --pdf FILE # smoke test a real PDF instead of a blank one

Exit status: 0 when everything works, 1 when anything is missing or broken.
"""

from __future__ import annotations

import argparse
import importlib
import importlib.metadata
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# binary -> flag that prints its version
BINARIES = {
    "pdftoppm": "-v",  # poppler tools take -v, not --version
    "pdftotext": "-v",
    "pdfinfo": "-v",
    "tesseract": "--version",
    "qpdf": "--version",
}

# import name -> distribution name (for version lookup)
MODULES = {
    "pypdf": "pypdf",
    "pdfplumber": "pdfplumber",
}

WIDTH = 14
failures: list[str] = []


def row(label: str, detail: str) -> None:
    print(f"  {label:<{WIDTH}} {detail}")


def problem(label: str, detail: str) -> None:
    failures.append(label)
    row(label, f"FAIL  {detail}")


def first_line(text: str) -> str:
    for line in text.splitlines():
        if line.strip():
            return line.strip()
    return ""


def check_binaries() -> None:
    print("== binaries ==")
    for name, flag in BINARIES.items():
        path = shutil.which(name)
        if path is None:
            problem(name, "not on PATH")
            continue
        try:
            proc = subprocess.run(
                [name, flag], capture_output=True, text=True, timeout=30, check=False
            )
        except (OSError, subprocess.SubprocessError) as exc:
            problem(name, f"{path} (version check failed: {exc})")
            continue
        # poppler prints its banner on stderr, tesseract/qpdf on stdout
        version = first_line(proc.stdout + proc.stderr) or "?"
        row(name, f"{path}  [{version}]")


def check_modules() -> None:
    print("== python ==")
    for module, dist in MODULES.items():
        try:
            importlib.import_module(module)
            version = importlib.metadata.version(dist)
        except ImportError:
            problem(dist, "not importable")
            continue
        except importlib.metadata.PackageNotFoundError:
            version = "?"
        row(dist, version)


def make_blank_pdf(path: Path) -> None:
    from pypdf import PdfWriter

    writer = PdfWriter()
    writer.add_blank_page(width=200, height=100)
    with path.open("wb") as fh:
        writer.write(fh)


def check_end_to_end(pdf: Path, generated: bool) -> None:
    print(f"== end-to-end (PDF -> PNG -> OCR): {pdf.name} ==")
    if generated:
        row("pypdf", f"wrote {pdf.name} ({pdf.stat().st_size} bytes)")

    prefix = pdf.with_name("page")
    proc = subprocess.run(
        ["pdftoppm", "-png", "-r", "150", "-f", "1", "-l", "1", str(pdf), str(prefix)],
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    if proc.returncode != 0:
        problem("pdftoppm", first_line(proc.stderr) or f"exit {proc.returncode}")
        return
    images = sorted(pdf.parent.glob("page*.png"))
    if not images:
        problem("pdftoppm", "produced no image")
        return
    row("pdftoppm", f"{images[0].name} ({images[0].stat().st_size} bytes)")

    result = subprocess.run(
        ["tesseract", str(images[0]), "-"],
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    if result.returncode != 0:
        problem("tesseract", first_line(result.stderr) or f"exit {result.returncode}")
        return
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    row("tesseract", f"OCR ok ({len(lines)} text line(s))")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-smoke", action="store_true", help="skip the end-to-end test")
    parser.add_argument("--pdf", type=Path, help="smoke test this PDF instead of a blank one")
    args = parser.parse_args()

    check_binaries()
    check_modules()

    if not args.no_smoke:
        with tempfile.TemporaryDirectory(prefix="pdf-tools-") as tmp:
            generated = args.pdf is None
            if generated:
                source: Path | None = Path(tmp) / "blank.pdf"
                make_blank_pdf(source)
            else:
                source = args.pdf.expanduser().resolve()
                if not source.is_file():
                    problem("--pdf", f"{source} not found")
                    source = None
            if source is not None:
                check_end_to_end(source, generated)

    print()
    if failures:
        print("RESULT: FAIL — not callable: " + ", ".join(failures))
        print("Fix: install the missing package wherever this skill's environment is provided,")
        print("     rebuild (nix run .#home-build), switch (nix run .#home-switch), restart pi.")
        return 1
    print("RESULT: OK — all PDF tooling is callable.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
