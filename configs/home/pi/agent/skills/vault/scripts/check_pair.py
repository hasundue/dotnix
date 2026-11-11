#!/usr/bin/env python3
"""Mechanical checks for a task note translation pair.

Usage:
    check_pair.py <draft-or-candidate> [candidate]

Compares `<note>.<lang>.md` with `<note>.en.md` on the mechanical rules of
`references/conventions.md`:

  - front matter fields agree
  - headings: one for one, same level order, none merged or dropped
  - acceptance criteria: one for one, same order, same `[ ]` / `[x]`,
    same `unmet:`, same number of `verify:` steps
  - code: fenced blocks and inline spans byte for byte, except backticked
    mentions of the note's own headings, which move with their heading
  - prose translated: no Japanese left outside code in the candidate
  - no quoted lines in either file
  - backticked heading references resolve, and to the paired heading

Run by the translator before the pair is handed over, and by the checker before
it reads. This is a pre-flight, not the check: whether the problem still states
the same problem, whether the prose reads as a translation rather than an
improvement, and whether a restatement quotes are for a reader who did not
translate the pair.

Exit status: 0 clean, 1 findings, 2 usage or file error.
"""

import argparse
import re
import sys
from pathlib import Path

EN_SUFFIX = ".en.md"
LANG_SUFFIX = re.compile(r"\.[a-z]{2}\.md$")

FENCE = re.compile(r"^\s*(```|~~~)")
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
CRITERION = re.compile(r"^- \[([ xX])\]\s*(.*)$")
SPAN = re.compile(r"`([^`]+)`")
HEADING_REF = re.compile(r"`(#{1,6})\s+([^`]+)`")
QUOTE = re.compile(r"^\s*>\s")
JAPANESE = re.compile(r"[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uff66-\uff9f]")
FRONT_KEY = re.compile(r"^([A-Za-z_][\w-]*):\s*(.*?)\s*$")

MAX_PER_CHECK = 20


class Report:
    def __init__(self):
        self.lines = []
        self.failed = False

    def section(self, name, findings, summary=""):
        if findings:
            self.failed = True
            self.lines.append(f"fail {name}: {len(findings)}")
        else:
            self.lines.append(f"ok   {name}" + (f" ({summary})" if summary else ""))
        for finding in findings[:MAX_PER_CHECK]:
            self.lines.append(f"       {finding}")
        if len(findings) > MAX_PER_CHECK:
            self.lines.append(f"       ... {len(findings) - MAX_PER_CHECK} more")


def read(path):
    return path.read_text(encoding="utf-8").splitlines()


def die(message):
    print(message, file=sys.stderr)
    raise SystemExit(2)


def resolve(argv):
    """Return (draft, candidate) or exit with a usage message."""
    if len(argv) == 2:
        draft, candidate = Path(argv[0]), Path(argv[1])
    else:
        path = Path(argv[0])
        name = path.name
        if name.endswith(EN_SUFFIX):
            candidate = path
            stem = name[: -len(EN_SUFFIX)]
            sibling = re.compile(re.escape(stem) + r"\.[a-z]{2}\.md$")
            siblings = sorted(
                p
                for p in path.parent.iterdir()
                if p.is_file()
                and sibling.search(p.name)
                and not p.name.endswith(EN_SUFFIX)
            )
            if len(siblings) != 1:
                die(
                    f"expected one draft next to {path}, found "
                    + (", ".join(p.name for p in siblings) if siblings else "none")
                )
            draft = siblings[0]
        elif LANG_SUFFIX.search(name):
            draft = path
            stem = name[: LANG_SUFFIX.search(name).start()]
            candidate = path.with_name(stem + EN_SUFFIX)
        else:
            die(
                f"{path.name} is not a translation pair: a plain .md is already "
                "promoted, and a pair is <note>.<lang>.md plus <note>.en.md"
            )

    for p in (draft, candidate):
        if not p.is_file():
            die(f"no such file: {p}")
    return draft, candidate


def view(lines):
    """Split lines into prose (fences blanked) and (line, fenced block) pairs."""
    prose, fenced = [], []
    start, block, inside = 0, [], False
    for i, line in enumerate(lines):
        if FENCE.match(line):
            if inside:
                fenced.append((start, "\n".join(block)))
                inside = False
            else:
                inside, start, block = True, i + 2, []
            prose.append("")
        elif inside:
            block.append(line)
            prose.append("")
        else:
            prose.append(line)
    if inside:
        fenced.append((start, "\n".join(block)))
    return prose, fenced


def front_matter(lines):
    if not lines or lines[0].strip() != "---":
        return {}
    data = {}
    for line in lines[1:]:
        if line.strip() == "---":
            return data
        match = FRONT_KEY.match(line)
        if match:
            data[match.group(1)] = match.group(2)
    return data


def headings(prose):
    out = []
    for i, line in enumerate(prose):
        match = HEADING.match(line)
        if match:
            out.append((len(match.group(1)), match.group(2).strip(), i + 1))
    return out


def criteria(prose):
    out, current = [], None
    for i, line in enumerate(prose):
        match = CRITERION.match(line)
        if match:
            current = {
                "state": match.group(1).lower(),
                "line": i + 1,
                "verify": 1 if "verify:" in match.group(2) else 0,
                "unmet": "unmet:" in match.group(2),
            }
            out.append(current)
            continue
        if current is None:
            continue
        if HEADING.match(line) or line.startswith("- "):
            current = None
            continue
        if "verify:" in line:
            current["verify"] += 1
        if "unmet:" in line:
            current["unmet"] = True
    return out


def spans(prose):
    """Inline code spans, minus mentions of this note's own headings."""
    out = []
    for i, line in enumerate(prose):
        for match in SPAN.finditer(line):
            if HEADING_REF.match(match.group(0)):
                continue
            out.append((i + 1, match.group(1)))
    return out


def heading_refs(prose):
    out = []
    for i, line in enumerate(prose):
        for match in HEADING_REF.finditer(line):
            out.append((i + 1, len(match.group(1)), match.group(2).strip()))
    return out


def resolve_heading(heads, level, text):
    for index, (lvl, title, _) in enumerate(heads):
        if lvl != level:
            continue
        if title == text or title.startswith(text) or text.startswith(title):
            return index
    return None


def check_front(draft_fm, candidate_fm):
    out = []
    if not draft_fm:
        out.append("the draft has no front matter")
    for key in sorted(set(draft_fm) | set(candidate_fm)):
        a, b = draft_fm.get(key), candidate_fm.get(key)
        if a != b:
            out.append(f"`{key}`: {a!r} in the draft, {b!r} in the candidate")
    return out


def check_headings(draft_heads, candidate_heads):
    out = []
    if len(draft_heads) != len(candidate_heads):
        out.append(
            f"{len(draft_heads)} headings in the draft, "
            f"{len(candidate_heads)} in the candidate"
        )
    for index, (draft, candidate) in enumerate(zip(draft_heads, candidate_heads), 1):
        if draft[0] != candidate[0]:
            out.append(
                f"heading {index} level: {'#' * draft[0]} {draft[1]!r} "
                f"vs {'#' * candidate[0]} {candidate[1]!r}"
            )
    return out


def check_criteria(draft_criteria, candidate_criteria):
    out = []
    if len(draft_criteria) != len(candidate_criteria):
        out.append(
            f"{len(draft_criteria)} criteria in the draft, "
            f"{len(candidate_criteria)} in the candidate"
        )
    for index, (draft, candidate) in enumerate(
        zip(draft_criteria, candidate_criteria), 1
    ):
        if draft["state"] != candidate["state"]:
            out.append(
                f"criterion {index} state: [{draft['state']}] in the draft "
                f"(line {draft['line']}), [{candidate['state']}] in the candidate "
                f"(line {candidate['line']})"
            )
        if draft["unmet"] != candidate["unmet"]:
            where = "the draft" if draft["unmet"] else "the candidate"
            out.append(f"criterion {index} has `unmet:` only in {where}")
        if draft["verify"] != candidate["verify"]:
            out.append(
                f"criterion {index}: {draft['verify']} verify step(s) in the draft, "
                f"{candidate['verify']} in the candidate"
            )
    return out


def check_fences(draft_fences, candidate_fences):
    out = []
    if len(draft_fences) != len(candidate_fences):
        out.append(
            f"{len(draft_fences)} fenced blocks in the draft, "
            f"{len(candidate_fences)} in the candidate"
        )
    for index, (draft, candidate) in enumerate(
        zip(draft_fences, candidate_fences), 1
    ):
        if draft[1] != candidate[1]:
            out.append(
                f"fenced block {index} differs "
                f"(draft line {draft[0]}, candidate line {candidate[0]})"
            )
            for line_no, (a, b) in enumerate(zip(draft[1].splitlines(), candidate[1].splitlines()), 1):
                if a != b:
                    out.append(f"  block line {line_no}: {a!r} vs {b!r}")
                    break
    return out


def check_spans(draft_spans, candidate_spans):
    out = []
    if [text for _, text in draft_spans] == [text for _, text in candidate_spans]:
        return out
    limit = max(len(draft_spans), len(candidate_spans))
    for index in range(limit):
        a = draft_spans[index] if index < len(draft_spans) else None
        b = candidate_spans[index] if index < len(candidate_spans) else None
        if a and b and a[1] == b[1]:
            continue
        if a and b:
            out.append(
                f"span {index + 1}: {a[1]!r} (draft line {a[0]}) "
                f"vs {b[1]!r} (candidate line {b[0]})"
            )
        else:
            side = "draft" if a else "candidate"
            line, text = a or b
            out.append(f"span {index + 1}: only in the {side} (line {line}): {text!r}")
    return out


def check_prose_language(prose, label):
    out = []
    for i, line in enumerate(prose):
        if JAPANESE.search(SPAN.sub(" ", line)):
            out.append(f"{label} line {i + 1}: {line.strip()[:100]}")
    return out


def check_quotes(prose, label):
    out = []
    for i, line in enumerate(prose):
        if QUOTE.match(line):
            out.append(f"{label} line {i + 1}: {line.strip()[:100]}")
    return out


def check_refs(draft_heads, candidate_heads, draft_refs, candidate_refs):
    out = []
    if len(draft_refs) != len(candidate_refs):
        out.append(
            f"{len(draft_refs)} heading references in the draft, "
            f"{len(candidate_refs)} in the candidate"
        )
    for index, (draft, candidate) in enumerate(zip(draft_refs, candidate_refs), 1):
        draft_target = resolve_heading(draft_heads, draft[1], draft[2])
        candidate_target = resolve_heading(candidate_heads, candidate[1], candidate[2])
        if draft_target is None:
            out.append(f"draft line {draft[0]}: {draft[2]!r} matches no heading")
        if candidate_target is None:
            out.append(f"candidate line {candidate[0]}: {candidate[2]!r} matches no heading")
        if (
            draft_target is not None
            and candidate_target is not None
            and draft_target != candidate_target
        ):
            out.append(
                f"reference {index} points at heading {draft_target + 1} in the draft "
                f"and heading {candidate_target + 1} in the candidate "
                f"({draft[2]!r} / {candidate[2]!r})"
            )
    return out


def main():
    parser = argparse.ArgumentParser(
        description="Mechanical checks for a task note translation pair.",
    )
    parser.add_argument(
        "paths",
        nargs="+",
        metavar="path",
        help="<note>.<lang>.md or <note>.en.md, or both (draft first)",
    )
    args = parser.parse_args()
    if len(args.paths) > 2:
        parser.error("give at most two paths: the draft and the candidate")

    draft_path, candidate_path = resolve(args.paths)
    draft_lines, candidate_lines = read(draft_path), read(candidate_path)
    draft_prose, draft_fences = view(draft_lines)
    candidate_prose, candidate_fences = view(candidate_lines)

    draft_heads, candidate_heads = headings(draft_prose), headings(candidate_prose)
    draft_criteria, candidate_criteria = criteria(draft_prose), criteria(candidate_prose)
    draft_spans, candidate_spans = spans(draft_prose), spans(candidate_prose)
    draft_refs, candidate_refs = heading_refs(draft_prose), heading_refs(candidate_prose)

    report = Report()
    report.section(
        "front matter",
        check_front(front_matter(draft_lines), front_matter(candidate_lines)),
    )
    report.section("headings", check_headings(draft_heads, candidate_heads))
    report.section(
        "criteria",
        check_criteria(draft_criteria, candidate_criteria),
        f"{len(draft_criteria)} paired",
    )
    report.section(
        "code",
        check_fences(draft_fences, candidate_fences)
        + check_spans(draft_spans, candidate_spans),
        f"{len(draft_fences)} fenced block(s), {len(draft_spans)} span(s)",
    )
    report.section(
        "prose translated",
        check_prose_language(candidate_prose, "candidate"),
        "no Japanese outside code in the candidate",
    )
    report.section(
        "quotations",
        check_quotes(draft_prose, "draft") + check_quotes(candidate_prose, "candidate"),
        "none",
    )
    report.section(
        "references",
        check_refs(draft_heads, candidate_heads, draft_refs, candidate_refs),
        f"{len(draft_refs)} heading reference(s)",
    )

    print(f"draft:     {draft_path}")
    print(f"candidate: {candidate_path}")
    print()
    print("\n".join(report.lines))
    print()
    if report.failed:
        print("not mechanically consistent: fix the findings, then re-run")
    else:
        print("mechanically consistent")
    print(
        "manual from here: the same problem, prose that reads as a translation\n"
        "rather than an improvement, restatements that quote, log entries one\n"
        "for one. A reader who did not translate the pair decides those."
    )
    return 1 if report.failed else 0


if __name__ == "__main__":
    sys.exit(main())
