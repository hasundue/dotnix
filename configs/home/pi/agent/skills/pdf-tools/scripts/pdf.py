#!/usr/bin/env python3
"""Read PDFs: decide text vs OCR, extract text and tables, render page images.

Subcommands:
    info     FILE               page count, metadata, text layer, column count
    text     FILE               extract text via pdftotext (--columns for two-up pages)
    pages    FILE --out DIR     render pages to PNG/JPEG via pdftoppm (--crop for a region)
    figures  FILE [--out DIR]   locate figures/tables by caption, optionally render them
    equations FILE [--out DIR]  locate numbered equations, optionally render them
    tables   FILE               extract tables via pdfplumber (tsv or markdown)
    ocr      FILE               render pages and run tesseract

Every subcommand accepts --pages (e.g. 1-5,8,12-). Output goes to stdout except
`pages` and `figures --out`, which write files and print their paths. Exit status
is 0 on success, 1 on a usage/processing error.

Run `pdf.py <subcommand> --help` for details.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

PAGE_MARK = "--- page {n} ---"


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #
def die(message: str) -> None:
    print(f"pdf.py: {message}", file=sys.stderr)
    raise SystemExit(1)


def page_count(pdf: Path) -> int:
    from pypdf import PdfReader

    try:
        return len(PdfReader(str(pdf)).pages)
    except Exception as exc:  # noqa: BLE001 - surface pypdf's message verbatim
        die(f"cannot read {pdf}: {exc}")
        return 0


def parse_pages(spec: str | None, total: int) -> list[int]:
    """Turn '1-5,8,12-' into a sorted list of 1-based page numbers."""
    if spec is None:
        return list(range(1, total + 1))
    pages: set[int] = set()
    for chunk in spec.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        if "-" in chunk:
            start_s, _, end_s = chunk.partition("-")
            start = int(start_s) if start_s.strip() else 1
            end = int(end_s) if end_s.strip() else total
        else:
            start = end = int(chunk)
        if start < 1 or end < start:
            die(f"bad page range {chunk!r}")
        if start > total:
            die(f"page {start} is out of range (file has {total} page(s))")
        pages.update(range(start, min(end, total) + 1))
    if not pages:
        die("no pages selected")
    return sorted(pages)


def runs(pages: list[int]) -> list[tuple[int, int]]:
    """Collapse 1-based page numbers into contiguous (first, last) runs."""
    out: list[tuple[int, int]] = []
    for page in pages:
        if out and page == out[-1][1] + 1:
            out[-1] = (out[-1][0], page)
        else:
            out.append((page, page))
    return out


def page_sizes(pdf: Path) -> list[tuple[float, float]]:
    from pypdf import PdfReader

    sizes: list[tuple[float, float]] = []
    for page in PdfReader(str(pdf)).pages:
        box = page.mediabox
        sizes.append((float(box.width), float(box.height)))
    return sizes


def detect_columns(pdf: Path, probe: int = 3) -> int:
    """Guess the number of text columns from word bounding boxes.

    Page 1 is skipped when possible: titles and abstracts often span the full
    width and would hide a two-column body. A layout only counts as N columns
    when almost no word crosses a strip boundary and every strip holds words.
    """
    import pdfplumber

    with pdfplumber.open(str(pdf)) as doc:
        pages = doc.pages[1 : 1 + probe] if len(doc.pages) > 1 else doc.pages[:1]
        for page in pages:
            words = page.extract_words()
            if len(words) < 40:
                continue
            width = page.width
            for columns in (3, 2):
                bounds = [width * i / columns for i in range(1, columns)]
                crossing = sum(
                    1 for word in words if any(word["x0"] < b < word["x1"] for b in bounds)
                )
                if crossing / len(words) > 0.02:
                    continue
                occupied = [0] * columns
                for word in words:
                    strip = min(int(word["x0"] / (width / columns)), columns - 1)
                    occupied[strip] += 1
                if all(count >= len(words) * 0.05 for count in occupied):
                    return columns
    return 1


def body_zone(pdf: Path, page_index: int, columns: int) -> float | None:
    """Return the y (from the page top) where the column region starts.

    Page 1 usually opens with a full-width title and abstract and only then drops
    into columns. Lines above the first column-width line are treated as full
    width; everything below is read strip by strip. Returns None when the page
    holds no column-width text (then the whole page is read full width, which
    also protects single-column pages from a mistaken --columns).
    """
    import pdfplumber

    with pdfplumber.open(str(pdf)) as doc:
        if page_index > len(doc.pages):
            return None
        page = doc.pages[page_index - 1]
        words = page.extract_words()
        if not words:
            return None
        width = page.width
        mid = width / 2
        buckets: dict[float, dict[str, list[dict]]] = {}
        for word in words:
            if word["x1"] <= mid + 1:
                side = "left"
            elif word["x0"] >= mid - 1:
                side = "right"
            else:
                side = "span"  # a word crossing the gutter
            slot = buckets.setdefault(round(word["top"] / 3), {"left": [], "right": [], "span": []})
            slot[side].append(word)

        body_like: list[float] = []
        for slot in buckets.values():
            if slot["span"]:
                continue  # a word crossing the gutter means one full-width line
            left, right = slot["left"], slot["right"]
            if left and right:
                gutter = min(w["x0"] for w in right) - max(w["x1"] for w in left)
                if gutter <= 0.03 * width:
                    continue  # continuous across the middle: a full-width line
                sides = [left, right]
            else:
                sides = [left or right]
            for group in sides:
                span = max(w["x1"] for w in group) - min(w["x0"] for w in group)
                if 0.10 * width < span < 0.55 * width:
                    body_like.append(min(w["top"] for w in group))
        if columns == 2:
            left = sum(1 for w in words if w["x1"] <= mid + 1)
            right = sum(1 for w in words if w["x0"] >= mid - 1)
            if left < 20 or right < 20 or not body_like:
                return None
        if not body_like:
            return None
        return min(body_like)


def caption_lines(page) -> list[dict]:
    """Text lines that look like figure or table captions (not prose mentions)."""
    import re

    # "FIG. 1." / "Figure 3:" / "TABLE II." — the trailing dot or colon is what
    # separates a caption from a sentence such as "Figure 3 shows ...".
    pattern = re.compile(
        r"^\s*(FIG|FIGURE|TABLE|TAB)\.?\s*[0-9IVXivx]+\s*[.:]", re.IGNORECASE
    )
    return [line for line in page.extract_text_lines() if pattern.match(line["text"])]


def ink_boxes(
    page, x_lo: float, x_hi: float, *, graphics_only: bool = False
) -> list[tuple[float, float, float, float]]:
    """Bounding boxes of what is drawn (or written) inside an x range."""
    groups = [page.images, page.curves, page.rects, page.lines]
    if not graphics_only:
        groups.append(page.chars)
    boxes: list[tuple[float, float, float, float]] = []
    for group in groups:
        for obj in group:
            if obj["x1"] <= x_lo or obj["x0"] >= x_hi:
                continue
            # ignore page-wide rules and hairlines, which are not artwork
            if obj["x1"] - obj["x0"] > 0.8 * page.width:
                continue
            if (obj["bottom"] - obj["top"]) < 1.5 and (obj["x1"] - obj["x0"]) > 0.5 * page.width:
                continue
            boxes.append((obj["x0"], obj["top"], obj["x1"], obj["bottom"]))
    return boxes


def figure_region(
    page, caption: dict, gap: float = 40.0
) -> tuple[float, float, float, float]:
    """Extent of the artwork that sits directly above a caption.

    The vertical run is found by walking up from the caption through graphics;
    the horizontal extent is widened to that same artwork, so a plot whose frame
    or axis labels stick out past the caption text is not cut off.
    """
    art = ink_boxes(page, caption["x0"], caption["x1"], graphics_only=True)
    above = [b for b in art if b[3] <= caption["top"]]
    top = caption["top"]
    for _, box_top, _, box_bottom in sorted(above, key=lambda b: b[3], reverse=True):
        if top - box_bottom > gap:
            break
        top = min(top, box_top)

    band = [b for b in art if b[3] > top and b[1] < caption["bottom"]]
    x0 = min([caption["x0"], *(b[0] for b in band)])
    x1 = max([caption["x1"], *(b[2] for b in band)])
    return x0, top, x1, caption["bottom"]


def snap_box(
    page, box: tuple[float, float, float, float], growth: float = 1.0
) -> tuple[float, float, float, float]:
    """Grow a crop box until it no longer cuts through any drawn or written ink.

    Objects that merely cross an edge are pulled in whole; objects that sit far
    outside are left alone, so a box grows to the next whitespace boundary rather
    than swallowing the page.
    """
    x0, y0, x1, y1 = box
    span_x, span_y = x1 - x0, y1 - y0
    objects = [
        (obj["x0"], obj["top"], obj["x1"], obj["bottom"])
        for group in (page.chars, page.curves, page.rects, page.lines, page.images)
        for obj in group
    ]
    for _ in range(8):
        changed = False
        for ox0, oy0, ox1, oy1 in objects:
            if ox1 <= x0 or ox0 >= x1 or oy1 <= y0 or oy0 >= y1:
                continue
            if ox0 >= x0 and ox1 <= x1 and oy0 >= y0 and oy1 <= y1:
                continue  # already fully inside
            nx0, ny0 = min(x0, ox0), min(y0, oy0)
            nx1, ny1 = max(x1, ox1), max(y1, oy1)
            if (
                nx0 < x0 - growth * span_x
                or nx1 > x1 + growth * span_x
                or ny0 < y0 - growth * span_y
                or ny1 > y1 + growth * span_y
            ):
                continue  # too far away to belong to this box
            x0, y0, x1, y1 = nx0, ny0, nx1, ny1
            changed = True
        if not changed:
            break
    return x0, y0, x1, y1


def column_boxes(width: float, columns: int) -> list[tuple[float, float]]:
    """(left, right) x extents for each column of a page."""
    return [(width * i / columns, width * (i + 1) / columns) for i in range(columns)]


# pdftotext -bbox-layout decodes custom font encodings that pdfplumber exposes as
# ``(cid:N)``. Equation tags in the wild use ordinary parentheses, fullwidth
# parentheses, or ASCII substitutes from a missing glyph map (``~1a!``).
_TAG_TRANSLATION = str.maketrans(
    {"共": "(", "兲": ")", "（": "(", "）": ")", "~": "(", "!": ")"}
)
_TAG_LABEL = r"[A-Z]?\.?\d+(?:\.\d+)*[a-z]?"
_TAG_RE = re.compile(rf"^[（(]\s*({_TAG_LABEL})\s*[)）][.,;:]?$")
_CID_TAG_RE = re.compile(rf"^\(\s*cid:\d+\s*\)\s*({_TAG_LABEL})\s*\(\s*cid:\d+\s*\)[.,;:]?$")
_YEAR_RE = re.compile(r"^(?:19|20)\d{2}$")
_XML_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")
EQUATION_GAP = 5.0


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _tag_label(word: str) -> str | None:
    """Return the equation number wrapped by a word, if it is a tag."""
    text = word.strip()
    match = _TAG_RE.match(text.translate(_TAG_TRANSLATION))
    if match:
        return match.group(1)
    match = _CID_TAG_RE.match(text)
    return match.group(1) if match else None


def layout_lines(pdf: Path, page: int) -> list[dict]:
    """Decoded text lines with PDF-point boxes from pdftotext's layout XML.

    pdfplumber's line text keeps unencoded glyphs as ``(cid:N)``; poppler
    resolves them, which is what makes equation-number detection reliable across
    old journal fonts.
    """
    proc = run(
        ["pdftotext", "-bbox-layout", "-f", str(page), "-l", str(page), str(pdf), "-"]
    )
    try:
        root = ET.fromstring(_XML_CONTROL.sub("", proc.stdout))
    except ET.ParseError as exc:
        die(f"pdftotext produced malformed layout XML for page {page}: {exc}")

    lines: list[dict] = []
    for element in root.iter():
        if _local_name(element.tag) != "line":
            continue
        words = [word for word in element.iter() if _local_name(word.tag) == "word"]
        if not words:
            continue
        lines.append(
            {
                "text": " ".join((word.text or "") for word in words),
                "words": [
                    (
                        word.text or "",
                        float(word.attrib["xMin"]),
                        float(word.attrib["yMin"]),
                        float(word.attrib["xMax"]),
                        float(word.attrib["yMax"]),
                    )
                    for word in words
                ],
                "x0": float(element.attrib["xMin"]),
                "top": float(element.attrib["yMin"]),
                "x1": float(element.attrib["xMax"]),
                "bottom": float(element.attrib["yMax"]),
            }
        )
    return lines


def equation_blocks(
    pdf: Path, page_number: int, page, columns: int
) -> list[tuple[str, tuple[float, float, float, float]]]:
    """Find displayed equations by their right-aligned number tag.

    Tags come from decoded pdftotext layout lines, so custom font encodings do
    not hide them. The equation body is the cluster of indented text and drawn
    rules around the tag; header/footer lines are excluded, and tags in the
    journal header year are ignored.
    """
    lines = layout_lines(pdf, page_number)
    if not lines:
        return []

    width, height = page.width, page.height
    body_top = 0.05 * height
    body_bottom = 0.97 * height
    graphics = [
        (obj["x0"], obj["top"], obj["x1"], obj["bottom"])
        for group in (page.lines, page.rects, page.curves, page.images)
        for obj in group
    ]
    found: list[tuple[str, tuple[float, float, float, float]]] = []

    for left, right in column_boxes(width, columns):
        column_lines = [line for line in lines if left - 1 <= line["x0"] < right]
        if not column_lines:
            continue
        body_lines = [line for line in column_lines if body_top <= line["top"] <= body_bottom]
        margin_lines = body_lines or column_lines
        text_left = min(line["x0"] for line in margin_lines)
        right_edges = [line["x1"] for line in margin_lines if line["x1"] < right - 3]
        text_right = max(right_edges or [max(line["x1"] for line in margin_lines)])
        indent = text_left + 12

        column_graphics = [box for box in graphics if box[2] > left and box[0] < right]
        items = [
            (line["x0"], line["top"], line["x1"], line["bottom"])
            for line in column_lines
            if line["x0"] >= indent
        ]
        items.extend(column_graphics)
        items.sort(key=lambda item: item[1])
        clusters: list[list[tuple[float, float, float, float]]] = []
        for item in items:
            if clusters and item[1] - max(box[3] for box in clusters[-1]) <= EQUATION_GAP:
                clusters[-1].append(item)
            else:
                clusters.append([item])

        page_found: list[tuple[str, tuple[float, float, float, float], float, float]] = []
        for line in column_lines:
            if not body_top <= line["top"] <= body_bottom:
                continue
            words = line["words"]
            if not words:
                continue
            label = _tag_label(words[-1][0])
            if label is None or _YEAR_RE.match(label):
                continue
            # a display is right-aligned; a prose citation ending in (N) is not
            if words[-1][3] < text_right - 6:
                continue
            cluster = next(
                (
                    candidate
                    for candidate in clusters
                    if min(item[1] for item in candidate)
                    <= line["top"]
                    <= max(item[3] for item in candidate)
                ),
                None,
            )
            if cluster is None:
                continue
            x0 = min(item[0] for item in cluster)
            x1 = max(item[2] for item in cluster)
            y0 = min(item[1] for item in cluster)
            y1 = max(item[3] for item in cluster)
            # Guard against a paragraph's indented first line dragging a whole
            # block into the crop; keep the tag line in range even if it does.
            if y1 - y0 > 0.35 * height:
                y0 = max(y0, line["top"] - 80)
                y1 = min(y1, line["bottom"] + 80)
            page_found.append(
                (label, (x0 - 2, y0 - 2, x1 + 2, y1 + 2), line["top"], x0)
            )
        page_found.sort(key=lambda item: (item[2], item[3]))
        found.extend((label, box) for label, box, _, _ in page_found)
    return found


def render_region(
    pdf: Path, page: int, region: tuple[float, float, float, float], out: Path, dpi: int
) -> Path:
    # pdftoppm's -x/-y/-W/-H are pixels of the rendered image, not PDF points, so
    # a box in points has to be scaled by dpi/72.
    x0, y0, x1, y1 = region
    scale = dpi / 72.0
    run(
        [
            "pdftoppm",
            "-png",
            "-r",
            str(dpi),
            "-f",
            str(page),
            "-l",
            str(page),
            "-x",
            str(int(x0 * scale)),
            "-y",
            str(int(y0 * scale)),
            "-W",
            str(max(1, int((x1 - x0) * scale))),
            "-H",
            str(max(1, int((y1 - y0) * scale))),
            str(pdf),
            str(out),
        ]
    )
    produced = sorted(out.parent.glob(f"{out.name}-*.png")) or [out.with_suffix(".png")]
    return produced[0]


def need(*binaries: str) -> None:
    missing = [b for b in binaries if shutil.which(b) is None]
    if missing:
        die(f"missing on PATH: {', '.join(missing)} (run verify-env.py)")


def run(argv: list[str], *, timeout: int = 300) -> subprocess.CompletedProcess[str]:
    proc = subprocess.run(argv, capture_output=True, text=True, timeout=timeout, check=False)
    if proc.returncode != 0:
        detail = (proc.stderr or proc.stdout).strip().splitlines()
        die(f"{argv[0]} failed ({proc.returncode}): {detail[0] if detail else 'no output'}")
    return proc


# --------------------------------------------------------------------------- #
# subcommands
# --------------------------------------------------------------------------- #
def cmd_info(args: argparse.Namespace) -> int:
    pdf = args.file
    total = page_count(pdf)
    probe = min(total, 3)

    import pdfplumber

    chars_per_page: list[int] = []
    with pdfplumber.open(str(pdf)) as doc:
        for page in doc.pages[:probe]:
            chars_per_page.append(len((page.extract_text() or "").strip()))
    # Scans yield ~0 characters; ordinary documents yield tens per page. Keep the
    # bar low so short one-page files (e.g. a single sentence) still count.
    text_layer = sum(chars_per_page) >= 10 * probe

    info: dict[str, object] = {
        "file": str(pdf),
        "pages": total,
        "text_layer": text_layer,
        "columns": detect_columns(pdf),
        "chars_on_first_pages": chars_per_page,
        "recommendation": "text" if text_layer else "ocr",
    }
    if shutil.which("pdfinfo"):
        proc = subprocess.run(
            ["pdfinfo", str(pdf)], capture_output=True, text=True, check=False
        )
        for line in proc.stdout.splitlines():
            key, _, value = line.partition(":")
            if key.strip() in {"Title", "Author", "Producer", "Creator", "Page size", "Encrypted"}:
                info[key.strip().lower().replace(" ", "_")] = value.strip()

    if args.json:
        print(json.dumps(info, indent=2))
    else:
        for key, value in info.items():
            print(f"{key:<22} {value}")
        if not text_layer:
            print("\nNo usable text layer: use `ocr` (text extraction would return little).")
        elif info["columns"] != 1:
            print(
                f"\nThis looks like {info['columns']} columns: use `text --columns "
                f"{info['columns']}` (start at --pages 2- if page 1 has a wide title)."
            )
        if text_layer:
            print(
                "\nUnsure about the layout? render and look: "
                f"`pages {pdf} --out /tmp/look --pages 1 --dpi 72`"
            )
    return 0


def cmd_text(args: argparse.Namespace) -> int:
    need("pdftotext")
    pdf = args.file
    pages = parse_pages(args.pages, page_count(pdf))
    columns = detect_columns(pdf) if args.columns == "auto" else int(args.columns)
    if columns == 1 and args.columns == "1":
        guessed = detect_columns(pdf)
        if guessed > 1:
            print(
                f"note: the layout looks like {guessed} columns, so this output "
                f"mixes them; use `--columns {guessed}` (or `--columns auto`)",
                file=sys.stderr,
            )
    chunks: list[str] = []

    if columns > 1:
        # Split each page into vertical strips and read them left to right, so a
        # two-column layout keeps its reading order. Full-width text above the
        # first column line (page 1's title and abstract) is read whole first.
        sizes = page_sizes(pdf)
        for number in pages:
            width, height = sizes[number - 1]
            start = body_zone(pdf, number, columns)
            if start is not None and start < 0.15 * height:
                # the columns start right at the top: no full-width head to carve
                # out (otherwise a few continuation lines get read interleaved)
                start = 0

            def crop(
                x: float, y: float, w: float, h: float, mode: str = args.mode
            ) -> str:
                return run(
                    [
                        "pdftotext",
                        f"-{mode}",
                        "-enc",
                        "UTF-8",
                        "-f",
                        str(number),
                        "-l",
                        str(number),
                        "-x",
                        str(int(x)),
                        "-y",
                        str(int(y)),
                        "-W",
                        str(int(w)),
                        "-H",
                        str(int(h)),
                        str(pdf),
                        "-",
                    ]
                ).stdout.strip()

            if start is None:
                # no column-width text: read full width rather than lose it
                body = crop(0, 0, width, height)
                if body:
                    chunks.append(f"--- page {number} ---\n{body}")
                continue
            if start > 20:
                head = crop(0, 0, width, start)
                if head:
                    chunks.append(f"--- page {number}, full width ---\n{head}")
            strip = width / columns
            for column in range(columns):
                body = crop(strip * column, start, strip, height - start)
                if body:
                    chunks.append(f"--- page {number}, column {column + 1} ---\n{body}")
        text = "\n\n".join(chunks)
    else:
        for first, last in runs(pages):
            proc = run(
                [
                    "pdftotext",
                    f"-{args.mode}",
                    "-enc",
                    "UTF-8",
                    "-f",
                    str(first),
                    "-l",
                    str(last),
                    str(pdf),
                    "-",
                ]
            )
            body = proc.stdout.strip()
            if len(pages) > 1:
                body = f"{PAGE_MARK.format(n=first if first == last else f'{first}-{last}')}\n{body}"
            chunks.append(body)
        text = "\n\n".join(chunk for chunk in chunks if chunk)

    if not text.strip():
        die("pdftotext produced no text; the pages are probably scanned (use `ocr`)")
    if len(text.strip()) < 40:
        if columns > 1:
            print(
                "note: very little text came out; the column split may be wrong "
                "(retry without --columns), or the pages are scanned (use `ocr`)",
                file=sys.stderr,
            )
        else:
            print(
                "note: very little text came out; if you expected more, the pages are "
                "probably scanned (use `ocr`)",
                file=sys.stderr,
            )
    print(trim(text, args.max_chars))
    return 0


def parse_box(spec: str) -> tuple[float, float, float, float]:
    """Parse 'x0,y0,x1,y1' in PDF points, measured from the page's top-left."""
    try:
        x0, y0, x1, y1 = (float(part) for part in spec.split(","))
    except ValueError:
        die("--crop expects x0,y0,x1,y1 in points (top-left origin)")
    if x1 <= x0 or y1 <= y0:
        die("--crop needs x1 > x0 and y1 > y0")
    return x0, y0, x1, y1


def cmd_pages(args: argparse.Namespace) -> int:
    need("pdftoppm")
    pdf = args.file
    pages = parse_pages(args.pages, page_count(pdf))
    out_dir = Path(args.out).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)
    crop = parse_box(args.crop) if args.crop else None

    if crop:
        # pdftoppm's -x/-y are points from the top-left corner, same as pdfplumber
        boxes: dict[int, tuple[float, float, float, float]] = {n: crop for n in pages}
        if args.snap:
            import pdfplumber

            with pdfplumber.open(str(pdf)) as doc:
                for number in pages:
                    if number <= len(doc.pages):
                        boxes[number] = snap_box(doc.pages[number - 1], crop)
            for number in pages:
                if boxes[number] != crop:
                    x0, y0, x1, y1 = boxes[number]
                    print(
                        f"page {number}: snapped crop to x{x0:.0f},y{y0:.0f},"
                        f"x{x1:.0f},y{y1:.0f}",
                        file=sys.stderr,
                    )
        written: list[Path] = []
        for number in pages:
            target = out_dir / f"{pdf.stem}-p{number}-crop"
            written.append(render_region(pdf, number, boxes[number], target, args.dpi))
        for path in written:
            print(path)
        return 0
    written: list[Path] = []
    for first, last in runs(pages):
        run(
            [
                "pdftoppm",
                f"-{args.format}",
                "-r",
                str(args.dpi),
                "-f",
                str(first),
                "-l",
                str(last),
                str(pdf),
                str(out_dir / pdf.stem),
            ]
        )
    # pdftoppm appends the page number, so one glob covers every run
    written = sorted(
        out_dir.glob(f"{pdf.stem}-*.{args.format}"),
        key=lambda p: int(p.stem.rsplit("-", 1)[-1]) if p.stem.rsplit("-", 1)[-1].isdigit() else 0,
    )
    if not written:
        die("pdftoppm produced no images")
    for path in written:
        print(path)
    return 0


def cmd_figures(args: argparse.Namespace) -> int:
    pdf = args.file
    pages = parse_pages(args.pages, page_count(pdf))
    need("pdftoppm") if args.out else None
    out_dir = Path(args.out).expanduser() if args.out else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)

    import pdfplumber

    found = 0
    with pdfplumber.open(str(pdf)) as doc:
        for number in pages:
            if number > len(doc.pages):
                break
            page = doc.pages[number - 1]
            for index, caption in enumerate(caption_lines(page), 1):
                found += 1
                x0, y0, x1, y1 = figure_region(page, caption)
                x0, y0 = x0 - args.padding, y0 - args.padding
                x1, y1 = x1 + args.padding, y1 + args.padding
                if y1 - y0 < 20:
                    continue
                label = "region"
                m = __import__("re").match(
                    r"\s*(fig|figure|table|tab)\.?\s*([0-9IVXivx]+)", caption["text"],
                    __import__("re").IGNORECASE,
                )
                if m:
                    kind = "table" if m.group(1).lower().startswith("tab") else "fig"
                    label = f"{kind}{m.group(2)}"
                head = (
                    f"page {number}  {label}  "
                    f"x={x0:.0f},y={y0:.0f},w={x1 - x0:.0f},h={y1 - y0:.0f}"
                )
                if out_dir:
                    target = out_dir / f"{pdf.stem}-p{number}-{label.lower()}"
                    path = render_region(pdf, number, (x0, y0, x1, y1), target, args.dpi)
                    print(f"{head}  -> {path}")
                else:
                    print(head)
    if not found:
        print(
            "no figure or table captions found; render the page and crop by hand "
            "with `pages --crop x0,y0,x1,y1`",
            file=sys.stderr,
        )
        return 1
    return 0


def cmd_equations(args: argparse.Namespace) -> int:
    need("pdftotext")
    pdf = args.file
    pages = parse_pages(args.pages, page_count(pdf))
    columns = detect_columns(pdf)
    out_dir = Path(args.out).expanduser() if args.out else None
    if out_dir:
        need("pdftoppm")
        out_dir.mkdir(parents=True, exist_ok=True)

    import pdfplumber

    found = 0
    with pdfplumber.open(str(pdf)) as doc:
        for number in pages:
            if number > len(doc.pages):
                break
            for label, region in equation_blocks(pdf, number, doc.pages[number - 1], columns):
                found += 1
                x0, y0, x1, y1 = region
                head = (
                    f"page {number}  eq {label}  "
                    f"x={x0:.0f},y={y0:.0f},w={x1 - x0:.0f},h={y1 - y0:.0f}"
                )
                if out_dir:
                    name = label.strip("()")
                    target = out_dir / f"{pdf.stem}-p{number}-eq{name}"
                    path = render_region(pdf, number, region, target, args.dpi)
                    print(f"{head}  -> {path}")
                else:
                    print(head)
    if not found:
        print(
            "no numbered display equations found; render the page and crop by "
            "hand with `pages --crop x0,y0,x1,y1 --snap`",
            file=sys.stderr,
        )
        return 1
    return 0


def cmd_tables(args: argparse.Namespace) -> int:
    pdf = args.file
    pages = parse_pages(args.pages, page_count(pdf))

    import pdfplumber

    found = 0
    # "lines" needs ruling lines; "text" infers columns from aligned whitespace,
    # which is what most papers and reports actually use.
    settings = (
        {"vertical_strategy": "text", "horizontal_strategy": "text"}
        if args.strategy == "text"
        else {}
    )
    with pdfplumber.open(str(pdf)) as doc:
        for number in pages:
            if number > len(doc.pages):
                break
            groups = doc.pages[number - 1].extract_tables(table_settings=settings)
            for index, rows in enumerate(groups, 1):
                found += 1
                if args.format == "md":
                    print(f"### page {number}, table {index}")
                    print(markdown_table(rows))
                    print()
                else:
                    for row in rows:
                        cells = [(cell or "").replace("\t", " ").replace("\n", " ") for cell in row]
                        print(f"{number}\t{index}\t" + "\t".join(cells))
    if not found:
        hint = "--strategy text" if args.strategy == "lines" else "`text`"
        print(
            f"no tables detected on pages {pages[0]}-{pages[-1]} "
            f"(retry with {hint}, or read the layout instead)",
            file=sys.stderr,
        )
        return 1
    return 0


def cmd_ocr(args: argparse.Namespace) -> int:
    need("pdftoppm", "tesseract")
    pdf = args.file
    pages = parse_pages(args.pages, page_count(pdf))
    total_chars = 0
    with tempfile.TemporaryDirectory(prefix="pdf-ocr-") as tmp:
        for number in pages:
            prefix = Path(tmp) / f"page-{number}"
            run(
                [
                    "pdftoppm",
                    "-png",
                    "-r",
                    str(args.dpi),
                    "-f",
                    str(number),
                    "-l",
                    str(number),
                    str(pdf),
                    str(prefix),
                ]
            )
            images = sorted(Path(tmp).glob(f"page-{number}-*.png")) or sorted(
                Path(tmp).glob(f"page-{number}.png")
            )
            if not images:
                die(f"pdftoppm produced no image for page {number}")
            proc = run(["tesseract", str(images[0]), "-", "-l", args.lang], timeout=600)
            body = proc.stdout.strip()
            total_chars += len(body)
            print(PAGE_MARK.format(n=number))
            print(body)
            print()
    if total_chars == 0:
        print(
            f"warning: OCR returned no text (lang={args.lang}); the page may be empty "
            "or the language data may be missing",
            file=sys.stderr,
        )
    return 0


# --------------------------------------------------------------------------- #
# formatting
# --------------------------------------------------------------------------- #
def trim(text: str, limit: int | None) -> str:
    if limit is None or len(text) <= limit:
        return text
    return text[:limit] + f"\n\n[... truncated at {limit} characters]"


def markdown_table(rows: list[list[str | None]]) -> str:
    if not rows:
        return ""
    width = max(len(row) for row in rows)
    grid = [[(cell or "").replace("\n", " ").strip() for cell in row] for row in rows]
    for row in grid:
        row.extend([""] * (width - len(row)))
    header, *body = grid
    lines = [
        "| " + " | ".join(header) + " |",
        "| " + " | ".join("---" for _ in header) + " |",
    ]
    lines.extend("| " + " | ".join(row) + " |" for row in body)
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# cli
# --------------------------------------------------------------------------- #
def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = parser.add_subparsers(dest="command", required=True)

    def add_file(p: argparse.ArgumentParser) -> None:
        p.add_argument("file", type=Path, help="PDF path")

    def add_pages(p: argparse.ArgumentParser) -> None:
        p.add_argument(
            "--pages",
            help="1-based page selection: 3, 1-5, 10-, or 1-3,7 (default: all pages)",
        )

    p = sub.add_parser("info", help="page count, metadata, text-layer detection")
    add_file(p)
    p.add_argument("--json", action="store_true", help="machine-readable output")
    p.set_defaults(func=cmd_info)

    p = sub.add_parser("text", help="extract text with pdftotext")
    add_file(p)
    add_pages(p)
    p.add_argument(
        "--mode",
        choices=("layout", "raw"),
        default="layout",
        help="layout keeps columns (default); raw keeps content-stream order",
    )
    p.add_argument("--max-chars", type=int, help="truncate output")
    p.add_argument(
        "--columns",
        default="1",
        metavar="N|auto",
        help="split each page into N vertical strips, read left to right; `auto` "
        "uses the column count reported by `info` (needed for two-column papers; "
        "titles on page 1 usually span the full width, so start from page 2)",
    )
    p.set_defaults(func=cmd_text)

    p = sub.add_parser("pages", help="render pages to images with pdftoppm")
    add_file(p)
    add_pages(p)
    p.add_argument("--out", required=True, help="output directory")
    p.add_argument("--dpi", type=int, default=150)
    p.add_argument("--format", choices=("png", "jpeg"), default="png")
    p.add_argument(
        "--crop",
        metavar="X0,Y0,X1,Y1",
        help="render only this box, in PDF points from the page's top-left corner",
    )
    p.add_argument(
        "--snap",
        action="store_true",
        help="grow --crop until it stops cutting through text or artwork",
    )
    p.set_defaults(func=cmd_pages)

    p = sub.add_parser("figures", help="locate (and optionally render) figures and tables")
    add_file(p)
    add_pages(p)
    p.add_argument("--out", help="render each region here; omit to only list boxes")
    p.add_argument("--dpi", type=int, default=150)
    p.add_argument("--padding", type=float, default=4.0, help="points added around each region")
    p.set_defaults(func=cmd_figures)

    p = sub.add_parser("equations", help="locate (and optionally render) numbered equations")
    add_file(p)
    add_pages(p)
    p.add_argument("--out", help="render each equation here; omit to only list boxes")
    p.add_argument("--dpi", type=int, default=200)
    p.set_defaults(func=cmd_equations)

    p = sub.add_parser("tables", help="extract tables with pdfplumber")
    add_file(p)
    add_pages(p)
    p.add_argument("--format", choices=("tsv", "md"), default="tsv")
    p.add_argument(
        "--strategy",
        choices=("lines", "text"),
        default="lines",
        help="lines: rely on ruling lines (default); text: infer columns from whitespace",
    )
    p.set_defaults(func=cmd_tables)

    p = sub.add_parser("ocr", help="render pages and OCR them with tesseract")
    add_file(p)
    add_pages(p)
    p.add_argument("--lang", default="eng", help="tesseract language (default: eng)")
    p.add_argument("--dpi", type=int, default=300, help="render resolution (default: 300)")
    p.set_defaults(func=cmd_ocr)

    args = parser.parse_args()
    if not args.file.is_file():
        die(f"no such file: {args.file}")
    columns = getattr(args, "columns", "1")
    if columns != "auto" and (not columns.isdigit() or int(columns) < 1):
        die("--columns takes a positive integer or `auto`")
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
