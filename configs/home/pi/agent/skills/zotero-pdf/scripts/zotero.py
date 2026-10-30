#!/usr/bin/env python3
"""Find a paper in Zotero and resolve its local PDF, using Zotero's local API.

Subcommands:
    search QUERY       list matching items with their keys and PDF availability
    attachments ITEM   list the attachments of an item
    path ITEM          print the local PDF path (ITEM may be an item or attachment)
    doctor             report attachments whose file is missing on disk
    start              run `zotero --headless` and wait for the local API
    stop               stop the instance this script started
    info ITEM          metadata and abstract

Zotero 7 must be running with "Allow other applications on this computer to
communicate with Zotero" enabled; the API is read-only.

Environment:
    ZOTERO_API         base URL (default http://127.0.0.1:23119/api/users/0)
    ZOTERO_AUTOSTART   when 1, start Zotero headless if the API is down
    ZOTERO_CMD         start command (default `zotero --headless`)
    ZOTERO_LOG         start log file (default /tmp/zotero-headless.log)

Exit status: 0 on success, 1 when Zotero is unreachable, the item is missing, or
no PDF attachment exists.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DEFAULT_API = "http://127.0.0.1:23119/api/users/0"
TIMEOUT = 15


def api_base() -> str:
    return os.environ.get("ZOTERO_API", DEFAULT_API).rstrip("/")


def die(message: str) -> None:
    print(f"zotero.py: {message}", file=sys.stderr)
    raise SystemExit(1)


def api_alive(timeout: float = 3.0) -> bool:
    try:
        with urllib.request.urlopen(f"{api_base()}/items?limit=1", timeout=timeout):
            return True
    except Exception:  # noqa: BLE001 - any failure means "not usable"
        return False


def api_state() -> tuple[bool, str]:
    """Return (usable, detail) so 403 and "not running" are not confused."""
    try:
        with urllib.request.urlopen(f"{api_base()}/items?limit=1", timeout=3.0):
            return True, "ok"
    except urllib.error.HTTPError as exc:
        if exc.code == 403:
            return False, (
                f"Zotero is running but the local API is disabled (HTTP 403); enable "
                "Settings → Advanced → 'Allow other applications on this computer to "
                "communicate with Zotero'"
            )
        return False, f"Zotero answered HTTP {exc.code}"
    except Exception:  # noqa: BLE001
        return False, f"nothing listening at {api_base()}"


def pid_path() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return Path(runtime) / "zotero-pdf.pid"


def _zotero_running() -> bool:
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            if "zotero" in (entry / "comm").read_text().strip().lower():
                return True
        except OSError:
            continue
    return False


def cmd_start(args: argparse.Namespace) -> int:
    usable, detail = api_state()
    if usable:
        print(f"Zotero API already reachable at {api_base()}")
        return 0
    # A running Zotero that merely has the local API switched off must not be
    # joined by a second instance: the profile is locked and the newcomer would
    # either open a window or die.
    if pids_on_port(api_port()) or _zotero_running():
        die(
            f"Zotero is already running but unusable: {detail}. Not starting a "
            "second instance; fix the running one instead."
        )
    command = shlex.split(os.environ.get("ZOTERO_CMD", "zotero --headless"))
    if not shutil.which(command[0]):
        die(f"cannot start Zotero: {command[0]} is not on PATH (set ZOTERO_CMD)")
    if "--headless" not in command:
        print(
            "note: ZOTERO_CMD has no --headless; a window will open",
            file=sys.stderr,
        )
    log = Path(os.environ.get("ZOTERO_LOG", "/tmp/zotero-headless.log"))
    with log.open("ab") as handle:
        proc = subprocess.Popen(command, stdout=handle, stderr=handle, start_new_session=True)
    # The launcher may fork, so record the whole group plus the command; stopping
    # by pid alone leaves the real zotero-bin behind.
    pid_path().write_text(
        json.dumps({"pid": proc.pid, "command": command, "log": str(log)})
    )
    deadline = time.time() + args.timeout
    while time.time() < deadline:
        if api_alive(2.0):
            print(
                f"Zotero API reachable at {api_base()} (group {proc.pid}, log {log})\n"
                "It keeps running; open the Zotero window later if you need it, "
                "or stop it with `zotero.py stop`."
            )
            return 0
        if proc.poll() is not None and not api_alive(1.0):
            # the launcher exiting is normal when it forks; only fail when nothing
            # is listening and the process is really gone
            if not _matching_pids(command):
                die(f"Zotero exited ({proc.returncode}); see {log}")
        time.sleep(1)
    die(
        f"Zotero started but {api_base()} did not answer within {args.timeout}s "
        f"(see {log}); a cold start can take ~1 minute, so retry with "
        "`--timeout 120`, and check Settings → Advanced for the local API"
    )
    return 1


def api_port() -> int:
    parsed = urllib.parse.urlparse(api_base())
    return parsed.port or 23119


def pids_on_port(port: int) -> list[int]:
    """PIDs holding a LISTEN socket on `port`, via /proc only."""
    inodes: set[str] = set()
    for name in ("/proc/net/tcp", "/proc/net/tcp6"):
        try:
            lines = Path(name).read_text().splitlines()[1:]
        except OSError:
            continue
        for line in lines:
            fields = line.split()
            if len(fields) < 10 or fields[3] != "0A":  # 0A = LISTEN
                continue
            try:
                local_port = int(fields[1].rsplit(":", 1)[1], 16)
            except (IndexError, ValueError):
                continue
            if local_port == port:
                inodes.add(fields[9])
    if not inodes:
        return []
    targets = {f"socket:[{inode}]" for inode in inodes}
    pids: list[int] = []
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            for fd in (entry / "fd").iterdir():
                if os.readlink(fd) in targets:
                    pids.append(int(entry.name))
                    break
        except OSError:
            continue
    return pids


def _is_zotero(pid: int) -> bool:
    try:
        return "zotero" in Path(f"/proc/{pid}/comm").read_text().strip().lower()
    except OSError:
        return False


def _matching_pids(command: list[str]) -> list[int]:
    """Zotero processes whose command line matches ours (forked children)."""
    pids: list[int] = []
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            argv = [p.decode(errors="replace") for p in (entry / "cmdline").read_bytes().split(b"\0") if p]
        except OSError:
            continue
        if not argv or "zotero" not in Path(argv[0]).name.lower():
            continue
        if all(token in argv for token in command if token != command[0]):
            pids.append(int(entry.name))
    return pids


def cmd_stop(args: argparse.Namespace) -> int:
    path = pid_path()
    if not path.exists():
        print("no pid file; nothing started by this skill", file=sys.stderr)
        return 1
    try:
        record = json.loads(path.read_text() or "{}")
    except json.JSONDecodeError:
        record = {"pid": int(path.read_text().strip() or 0)}
    group = int(record.get("pid") or 0)
    command = record.get("command") or []

    killed: list[int] = []
    for signum in (15, 9):
        candidates = set(pids_on_port(api_port()))
        candidates.update(pid for pid in (_matching_pids(command) if command else []) if _is_zotero(pid))
        if group:
            candidates.add(group)
        for pid in candidates:
            if not _is_zotero(pid) and pid != group:
                continue
            try:
                os.kill(pid, signum)
                killed.append(pid)
            except (ProcessLookupError, PermissionError):
                pass
        if group:
            try:
                os.killpg(group, signum)
                killed.append(group)
            except (ProcessLookupError, PermissionError):
                pass
        time.sleep(2)
        if not api_alive(1.0) and not pids_on_port(api_port()):
            break

    path.unlink(missing_ok=True)
    if api_alive(1.0):
        die("Zotero still answers after stop; it may have been started outside this skill")
    print(f"stopped Zotero ({', '.join(str(p) for p in sorted(set(killed))) or 'no process'})")
    return 0


def ensure_api() -> None:
    """Start Zotero on demand when ZOTERO_AUTOSTART is set."""
    usable, detail = api_state()
    if usable:
        return
    if os.environ.get("ZOTERO_AUTOSTART", "").lower() in {"1", "true", "yes"}:
        print(f"starting Zotero ({detail})…", file=sys.stderr)
        cmd_start(argparse.Namespace(timeout=120))
        return
    die(
        f"cannot use Zotero: {detail}. Start it, or set ZOTERO_AUTOSTART=1 to let "
        "this script run `zotero --headless` on demand"
    )


def get(path: str) -> dict | list:
    url = f"{api_base()}/{path.lstrip('/')}"
    try:
        with urllib.request.urlopen(url, timeout=TIMEOUT) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            die(f"not found: {path}")
        die(f"Zotero API returned HTTP {exc.code} for {url}")
    except urllib.error.URLError as exc:
        die(
            f"cannot reach Zotero at {api_base()} ({exc.reason}); start Zotero and "
            "enable Settings → Advanced → 'Allow other applications on this "
            "computer to communicate with Zotero'"
        )
    return {}


def item(key: str) -> dict:
    data = get(f"items/{key}")
    if not isinstance(data, dict):
        die(f"unexpected response for item {key}")
    return data


def children(key: str) -> list[dict]:
    data = get(f"items/{key}/children")
    return data if isinstance(data, list) else []


def is_pdf(entry: dict) -> bool:
    meta = entry.get("data", {})
    content_type = (meta.get("contentType") or "").lower()
    if "pdf" in content_type:
        return True
    name = meta.get("filename") or meta.get("title") or ""
    return str(name).lower().endswith(".pdf")


def enclosure_path(entry: dict) -> Path | None:
    href = (entry.get("links", {}).get("enclosure", {}) or {}).get("href")
    if not href:
        return None
    raw = href[len("file://") :] if href.startswith("file://") else href
    return Path(urllib.parse.unquote(raw))


def pdf_of(entry: dict) -> tuple[Path | None, str]:
    """Resolve the PDF file for an item or attachment entry."""
    key = entry.get("key", "?")
    meta = entry.get("data", {})
    if meta.get("itemType") == "attachment":
        if not is_pdf(entry):
            return None, f"{key} is an attachment but not a PDF ({meta.get('contentType')})"
        return enclosure_path(entry), key
    for child in children(key):
        if child.get("data", {}).get("itemType") == "attachment" and is_pdf(child):
            return enclosure_path(child), child.get("key", "?")
    return None, f"{key} has no PDF attachment"


def year_of(meta: dict) -> str:
    match = re.search(r"\d{4}", str(meta.get("date") or ""))
    return match.group(0) if match else "n.d."


def first_author(meta: dict) -> str:
    creators = meta.get("creators") or []
    for creator in creators:
        name = creator.get("lastName") or creator.get("name")
        if name:
            return str(name)
    return "?"


def cmd_search(args: argparse.Namespace) -> int:
    query = urllib.parse.quote(args.query)
    # Zotero matches attachment titles too, and the limit applies before we can
    # drop them, so fetch a wider window than the caller asked for.
    window = max(args.limit * 4, 20)
    params = f"items?q={query}&limit={window}"
    if args.mode:
        params += f"&qmode={args.mode}"
    results = get(params)
    if not isinstance(results, list):
        die("unexpected search response")

    rows: list[dict] = []
    seen: set[str] = set()
    parents: list[str] = []
    for entry in results:
        meta = entry.get("data", {})
        key = entry.get("key", "")
        if meta.get("itemType") == "attachment":
            # remember the parent so a query that only hits attachment titles
            # ("PDF", "APS Snapshot") can still resolve to the paper
            parent = meta.get("parentItem")
            if parent and parent not in parents:
                parents.append(parent)
            continue
        if key and key not in seen:
            seen.add(key)
            rows.append(entry)

    if not rows and parents:
        for parent in parents[: args.limit]:
            entry = item(parent)
            key = entry.get("key", "")
            if key and key not in seen:
                seen.add(key)
                rows.append(entry)

    rows = rows[: args.limit]
    if not rows:
        print("no matching items", file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps([{"key": r["key"], **r["data"]} for r in rows], indent=2))
        return 0
    for entry in rows:
        meta = entry["data"]
        print(
            f"{entry['key']}  {year_of(meta):<4}  {meta.get('itemType', '?'):<13}  "
            f"{first_author(meta):<16}  {(meta.get('title') or 'untitled')[:80]}"
        )
    return 0


def cmd_attachments(args: argparse.Namespace) -> int:
    entry = item(args.item)
    listing = (
        [entry]
        if entry.get("data", {}).get("itemType") == "attachment"
        else children(args.item)
    )
    if not listing:
        print("no attachments", file=sys.stderr)
        return 1
    for child in listing:
        meta = child.get("data", {})
        path = enclosure_path(child)
        print(
            f"{child.get('key', '?'):8}  {meta.get('contentType') or '?':<16}  "
            f"{path if path else '(no local file)'}"
        )
    return 0


def cmd_doctor(args: argparse.Namespace) -> int:
    """Report attachments whose file is not readable on this disk."""
    entries: list[dict] = []
    start = 0
    while True:
        chunk = get(f"items?itemType=attachment&limit=100&start={start}")
        if not isinstance(chunk, list):
            die("unexpected response while listing attachments")
        entries.extend(chunk)
        if len(chunk) < 100:
            break
        start += 100

    pdfs = [entry for entry in entries if is_pdf(entry)]
    present: list[dict] = []
    missing_file: list[dict] = []
    no_path: list[dict] = []
    for entry in pdfs:
        path = enclosure_path(entry)
        if path is None:
            no_path.append(entry)
        elif path.exists():
            present.append(entry)
        else:
            missing_file.append(entry)

    print(
        f"attachments: {len(entries)} | pdf: {len(pdfs)} | on disk: {len(present)} | "
        f"file missing: {len(missing_file)} | no local path: {len(no_path)}"
    )
    for entry in missing_file:
        meta = entry.get("data", {})
        print(f"\nmissing file  {entry.get('key')}  {(meta.get('title') or '')[:60]}")
        print(f"  expected at  {enclosure_path(entry)}")
    for entry in no_path:
        meta = entry.get("data", {})
        print(f"\nno local path {entry.get('key')}  {(meta.get('title') or '')[:60]}")
        print(f"  linkMode     {meta.get('linkMode')}")

    if missing_file or no_path:
        print(
            "\nThese are in the library but not readable here. Zotero stores files "
            "when it saves them, but with on-demand download enabled they arrive "
            "only after the item is opened: open it once in Zotero, or turn off "
            "Settings → Sync → 'Download files as needed'.",
            file=sys.stderr,
        )
        return 1
    return 0


def slugify(text: str, limit: int = 60) -> str:
    text = re.sub(r"[^\w\s.-]", "", text, flags=re.UNICODE)
    text = re.sub(r"\s+", "_", text.strip())
    return text[:limit].strip("._") or "paper"


def cmd_path(args: argparse.Namespace) -> int:
    entry = item(args.item)
    path, source = pdf_of(entry)
    if path is None:
        die(source)
    if not path.exists():
        die(f"{source} points at {path}, which does not exist (is the file on disk?)")
    if not args.copy_to:
        print(path)
        return 0

    meta = entry.get("data", {})
    if meta.get("itemType") == "attachment":
        name = meta.get("filename") or path.name
    else:
        name = f"{year_of(meta)}_{first_author(meta)}_{meta.get('title') or path.stem}"
    target = Path(args.copy_to).expanduser() / (slugify(name) + ".pdf")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)
    print(target)
    return 0


def cmd_info(args: argparse.Namespace) -> int:
    entry = item(args.item)
    meta = entry.get("data", {})
    if args.json:
        print(json.dumps({"key": entry.get("key"), **meta}, indent=2))
        return 0
    authors = ", ".join(
        f"{c.get('firstName', '')} {c.get('lastName', '')}".strip()
        or c.get("name", "")
        for c in meta.get("creators") or []
    )
    fields = [
        ("key", entry.get("key")),
        ("type", meta.get("itemType")),
        ("title", meta.get("title")),
        ("authors", authors),
        ("date", meta.get("date")),
        ("publication", meta.get("publicationTitle") or meta.get("proceedingsTitle")),
        ("volume", meta.get("volume")),
        ("pages", meta.get("pages")),
        ("doi", meta.get("DOI")),
        ("url", meta.get("url")),
    ]
    for label, value in fields:
        if value:
            print(f"{label:<12} {value}")
    abstract = (meta.get("abstractNote") or "").strip()
    if abstract:
        print(f"\n{abstract}\n")
    path, source = pdf_of(entry)
    if path is None:
        print(f"pdf          none ({source})")
    else:
        state = "ok" if path.exists() else "MISSING ON DISK"
        print(f"pdf          {path} [{source}, {state}]")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("search", help="search the library")
    p.add_argument("query")
    p.add_argument("--limit", type=int, default=10)
    p.add_argument(
        "--mode",
        choices=("titleCreatorYear", "everything"),
        default="everything",
        help="Zotero search mode (default: everything)",
    )
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_search)

    p = sub.add_parser("attachments", help="list an item's attachments")
    p.add_argument("item", help="item key")
    p.set_defaults(func=cmd_attachments)

    p = sub.add_parser("path", help="print the local PDF path")
    p.add_argument("item", help="item key (journal article) or attachment key")
    p.add_argument(
        "--copy-to",
        metavar="DIR",
        help="copy the PDF into DIR under a clean file name and print that path",
    )
    p.set_defaults(func=cmd_path)

    p = sub.add_parser("doctor", help="check which attachments are not readable on disk")
    p.set_defaults(func=cmd_doctor)

    p = sub.add_parser("start", help="start Zotero headless in the background")
    p.add_argument("--timeout", type=int, default=120, help="seconds to wait for the API")
    p.set_defaults(func=cmd_start)

    p = sub.add_parser("stop", help="stop a Zotero instance this script started")
    p.set_defaults(func=cmd_stop)

    p = sub.add_parser("info", help="show metadata, abstract, and PDF status")
    p.add_argument("item", help="item key")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_info)

    args = parser.parse_args()
    if args.command not in {"start", "stop"}:
        ensure_api()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
