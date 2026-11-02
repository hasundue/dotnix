#!/usr/bin/env python3
"""Resolve a Zotero item to a local PDF file, using the Zotero Web API.

Searching and metadata belong to the `zotero` MCP server (zotero-mcp); this
script only fetches the attachment bytes, which MCP does not expose, and
diagnoses the setup.

Subcommands:
    path ITEM          download the PDF if needed and print its local path
    attachments ITEM   list an item's attachments and whether they are cached
    doctor             check the API key, the library, and file availability
    library            print the configured library ("user:<id>" or "group:<id>")

No Zotero installation is needed: everything goes through api.zotero.org, so
this works on any machine with network access and an API key with read access
to the library. The API is read-only.

Environment:
    ZOTERO_API_KEY      API key (takes precedence over ZOTERO_API_KEY_FILE)
    ZOTERO_API_KEY_FILE file holding the key (default: api_key_file in config)
    ZOTERO_LIBRARY      "user:<id>" or "group:<id>" (default: derived from the key)
    ZOTERO_API         base URL (default https://api.zotero.org)
    ZOTERO_CONFIG      config file (default ~/.config/zotero-pdf/config.json)
    ZOTERO_CACHE       download cache (default ~/.cache/zotero-pdf)

The config file holds {"library": "...", "api_key_file": "..."}; both fields are
optional. Downloads are cached under the cache directory by attachment key and
reused until the attachment's md5 changes; `path --refresh` forces a new one.

Exit status: 0 on success, 1 on any failure (missing or invalid key, unreachable
API, missing item, or no downloadable PDF).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DEFAULT_API = "https://api.zotero.org"
API_VERSION = "3"
TIMEOUT = 30
MAX_LIMIT = 100
KEY_SETTINGS_URL = "https://www.zotero.org/settings/keys/new"

# linkMode values whose bytes Zotero File Storage actually holds. linked_file
# and linked_url point at something outside the library, so the Web API cannot
# serve them.
STORED_LINK_MODES = {"imported_file", "imported_url", "embedded_image"}


def die(message: str) -> None:
    print(f"zotero.py: {message}", file=sys.stderr)
    raise SystemExit(1)


def note(message: str) -> None:
    print(f"zotero.py: {message}", file=sys.stderr)


def api_base() -> str:
    return os.environ.get("ZOTERO_API", DEFAULT_API).rstrip("/")


def xdg_dir(variable: str, fallback: str) -> Path:
    return Path(os.environ.get(variable) or Path.home() / fallback)


def config_path() -> Path:
    configured = os.environ.get("ZOTERO_CONFIG")
    if configured:
        return Path(configured).expanduser()
    return xdg_dir("XDG_CONFIG_HOME", ".config") / "zotero-pdf" / "config.json"


def cache_dir() -> Path:
    configured = os.environ.get("ZOTERO_CACHE")
    if configured:
        return Path(configured).expanduser()
    return xdg_dir("XDG_CACHE_HOME", ".cache") / "zotero-pdf"


def read_config() -> dict:
    path = config_path()
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        die(f"cannot read config {path}: {exc}")
    if not isinstance(data, dict):
        die(f"config {path} must be a JSON object")
    return data


def resolve_key() -> str:
    key = os.environ.get("ZOTERO_API_KEY", "").strip()
    if key:
        return key
    configured = os.environ.get("ZOTERO_API_KEY_FILE") or read_config().get("api_key_file")
    path = (
        Path(configured).expanduser()
        if configured
        else config_path().with_name("api-key")
    )
    if path.exists():
        try:
            key = path.read_text().strip()
        except OSError as exc:
            die(f"cannot read the API key from {path}: {exc}")
        if key:
            return key
    die(
        "no Zotero API key. Set ZOTERO_API_KEY, point ZOTERO_API_KEY_FILE at a file "
        f"holding the key, or set api_key_file in {config_path()}. Create a key at "
        f"{KEY_SETTINGS_URL} with library read access and file downloads allowed."
    )
    return ""


def fingerprint(key: str) -> str:
    return hashlib.sha256(key.encode()).hexdigest()[:16]


def normalize_library(value: str) -> str:
    text = value.strip().lower()
    if text.isdigit():
        return f"user:{text}"
    match = re.fullmatch(r"(user|users|group|groups)[:/](\d+)", text)
    if not match:
        die(f"bad library {value!r}: expected user:<id> or group:<id>")
    kind = "group" if match.group(1).startswith("group") else "user"
    return f"{kind}:{match.group(2)}"


def library_prefix(library: str) -> str:
    kind, _, number = library.partition(":")
    return f"{'groups' if kind == 'group' else 'users'}/{number}"


def resolve_library(key: str) -> str:
    configured = os.environ.get("ZOTERO_LIBRARY") or read_config().get("library")
    if configured:
        return normalize_library(str(configured))

    # The numeric userID is not memorable and is visible on the API keys page
    # only, so derive it from the key and remember it per key.
    marker = cache_dir() / "library.json"
    if marker.exists():
        try:
            record = json.loads(marker.read_text())
        except (OSError, json.JSONDecodeError):
            record = {}
        if record.get("fingerprint") == fingerprint(key) and record.get("library"):
            return normalize_library(str(record["library"]))

    info = key_info(key)
    user_id = info.get("userID")
    if not user_id:
        die("cannot determine the library: /keys/<key> returned no userID; set ZOTERO_LIBRARY")
    library = f"user:{user_id}"
    try:
        marker.parent.mkdir(parents=True, exist_ok=True)
        marker.write_text(json.dumps({"fingerprint": fingerprint(key), "library": library}))
    except OSError:
        pass
    return library


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def _request(url: str, key: str | None = None, timeout: float = TIMEOUT, follow: bool = True):
    request = urllib.request.Request(
        url,
        headers={
            "Zotero-API-Version": API_VERSION,
            "Accept": "application/json",
            "User-Agent": "zotero-pdf (pi agent skill)",
        },
    )
    if key:
        request.add_header("Zotero-API-Key", key)
    opener = urllib.request.build_opener(*([] if follow else [_NoRedirect()]))
    try:
        return opener.open(request, timeout=timeout)
    except urllib.error.HTTPError as exc:
        return exc
    except urllib.error.URLError as exc:
        die(
            f"cannot reach the Zotero Web API at {api_base()} ({exc.reason}); "
            "check the network and retry"
        )
    raise AssertionError("unreachable")


def status_of(response) -> int:
    return int(getattr(response, "status", None) or getattr(response, "code", 0))


def error_detail(body: bytes) -> str:
    try:
        data = json.loads(body.decode("utf-8", "replace"))
    except (ValueError, AttributeError):
        return ""
    if isinstance(data, dict) and data.get("error"):
        return str(data["error"])
    return ""


def explain(status: int, body: bytes, url: str) -> str:
    detail = error_detail(body)
    shown = re.sub(r"key=[^&]+", "key=REDACTED", url)
    suffix = f" ({detail})" if detail else ""
    if status == 403:
        return (
            "the Zotero Web API answered 403 (forbidden): the API key is invalid, "
            "expired, or lacks read access to this library. Check the key at "
            f"{KEY_SETTINGS_URL} and the library setting{suffix}"
        )
    if status == 404:
        return f"not found: {shown}{suffix}"
    return f"the Zotero Web API answered HTTP {status} for {shown}{suffix}"


def retry_delay(headers, attempt: int) -> float:
    for name in ("Retry-After", "Backoff"):
        value = headers.get(name) if headers is not None else None
        if value:
            try:
                return min(float(value), 60.0)
            except ValueError:
                continue
    return min(2.0**attempt, 30.0)


def get_json(
    path: str,
    key: str,
    params: dict | None = None,
    want_headers: bool = False,
):
    url = path if path.startswith("http") else f"{api_base()}/{path.lstrip('/')}"
    if params:
        url += ("&" if "?" in url else "?") + urllib.parse.urlencode(params)
    for attempt in range(4):
        response = _request(url, key=key)
        try:
            status = status_of(response)
            body = response.read()
            headers = response.headers
        finally:
            response.close()
        if status == 200:
            data = json.loads(body or b"null")
            return (data, headers) if want_headers else data
        if status in (429, 503) and attempt < 3:
            delay = retry_delay(headers, attempt)
            note(f"rate limited (HTTP {status}); retrying in {delay:.0f}s")
            time.sleep(delay)
            continue
        die(explain(status, body, url))
    die("the Zotero Web API keeps rate limiting this client; try again later")
    return None


def key_info(key: str) -> dict:
    data = get_json(f"keys/{urllib.parse.quote(key)}", key)
    return data if isinstance(data, dict) else {}


def has_permission(info: dict, library: str, field: str) -> bool | None:
    access = info.get("access") or {}
    kind, _, number = library.partition(":")
    if kind == "group":
        entry = (access.get("groups") or {}).get(number)
    else:
        entry = access.get("user")
    if not isinstance(entry, dict):
        return None
    return bool(entry.get(field))


def item(item_key: str, library: str, key: str) -> dict:
    data = get_json(f"{library_prefix(library)}/items/{item_key}", key)
    if not isinstance(data, dict):
        die(f"unexpected response for item {item_key}")
    return data


def iter_pages(path: str, key: str, params: dict | None = None):
    start = 0
    while True:
        query = dict(params or {})
        query.update({"limit": MAX_LIMIT, "start": start})
        chunk = get_json(path, key, query)
        if not isinstance(chunk, list):
            die(f"unexpected response from {path}")
        yield from chunk
        if len(chunk) < MAX_LIMIT:
            return
        start += MAX_LIMIT


def total_results(path: str, key: str, params: dict | None = None) -> str:
    query = dict(params or {})
    query["limit"] = 1
    _, headers = get_json(path, key, query, want_headers=True)
    value = headers.get("Total-Results") if headers is not None else None
    return str(value) if value else "?"


def children(item_key: str, library: str, key: str) -> list[dict]:
    return list(iter_pages(f"{library_prefix(library)}/items/{item_key}/children", key))


def is_pdf(entry: dict) -> bool:
    meta = entry.get("data", {})
    if "pdf" in str(meta.get("contentType") or "").lower():
        return True
    name = meta.get("filename") or meta.get("title") or ""
    return str(name).lower().endswith(".pdf")


def downloadable(entry: dict) -> bool:
    mode = entry.get("data", {}).get("linkMode")
    return mode is None or mode in STORED_LINK_MODES


def pdf_attachment(entry: dict, library: str, key: str) -> dict | None:
    """The item's own data if it is a PDF attachment, else its first PDF child."""
    meta = entry.get("data", {})
    if meta.get("itemType") == "attachment":
        return entry if is_pdf(entry) else None
    for child in children(entry.get("key", ""), library, key):
        if child.get("data", {}).get("itemType") == "attachment" and is_pdf(child):
            return child
    return None


def unavailable_reason(entry: dict) -> str:
    meta = entry.get("data", {})
    att = entry.get("key", "?")
    mode = meta.get("linkMode")
    if mode == "linked_file":
        return (
            f"{att} is a linked file; its bytes live on the computer that added it, "
            "so the Web API cannot serve it"
        )
    if mode == "linked_url":
        return f"{att} is a link to a URL ({mode}), not a stored file"
    return f"{att} has no file stored in Zotero File Storage"


def year_of(meta: dict) -> str:
    match = re.search(r"\d{4}", str(meta.get("date") or ""))
    return match.group(0) if match else "n.d."


def first_author(meta: dict) -> str:
    for creator in meta.get("creators") or []:
        name = creator.get("lastName") or creator.get("name")
        if name:
            return str(name)
    return "?"


def safe_name(name: str) -> str:
    name = Path(str(name)).name
    name = re.sub(r"[^\w.()\[\] \-]", "_", name, flags=re.UNICODE).strip(" .")
    return name or "file.pdf"


def cached_path(entry: dict) -> Path:
    meta = entry.get("data", {})
    name = meta.get("filename") or f"{entry.get('key', 'file')}.pdf"
    return cache_dir() / "files" / str(entry.get("key", "unknown")) / safe_name(name)


def md5_of(path: Path) -> str:
    digest = hashlib.md5()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_bytes(url: str, key: str) -> bytes:
    response = _request(url, key=key, follow=False)
    try:
        status = status_of(response)
        location = response.headers.get("Location")
        if status in (301, 302, 303, 307, 308) and location:
            response.close()
            # Storage redirects to a pre-signed URL: never forward the API key.
            response = _request(location, key=None, follow=False)
            status = status_of(response)
        if status != 200:
            die(f"cannot download the file: {explain(status, response.read(), url)}")
        return response.read()
    finally:
        response.close()


def download(entry: dict, library: str, key: str, refresh: bool = False) -> Path:
    if not downloadable(entry):
        die(unavailable_reason(entry))
    target = cached_path(entry)
    expected = (entry.get("data", {}).get("md5") or "").lower() or None
    if target.exists() and not refresh:
        if expected is None or md5_of(target) == expected:
            return target
        note("cached file no longer matches the attachment; downloading again")
    url = f"{api_base()}/{library_prefix(library)}/items/{entry.get('key')}/file"
    body = download_bytes(url, key)
    if expected and hashlib.md5(body).hexdigest() != expected:
        note(
            "warning: the downloaded file does not match the attachment's md5 "
            "(the stored file and its metadata disagree); using it anyway"
        )
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + ".part")
    temporary.write_bytes(body)
    os.replace(temporary, target)
    return target


def slugify(text: str, limit: int = 60) -> str:
    text = re.sub(r"[^\w\s.-]", "", text, flags=re.UNICODE)
    text = re.sub(r"\s+", "_", text.strip())
    return text[:limit].strip("._") or "paper"


def cmd_library(args: argparse.Namespace, library: str, key: str) -> int:
    print(library)
    return 0


def cmd_attachments(args: argparse.Namespace, library: str, key: str) -> int:
    entry = item(args.item, library, key)
    listing = (
        [entry]
        if entry.get("data", {}).get("itemType") == "attachment"
        else children(args.item, library, key)
    )
    if not listing:
        print("no attachments", file=sys.stderr)
        return 1
    for child in listing:
        meta = child.get("data", {})
        name = meta.get("filename") or meta.get("url") or "-"
        state = "cached" if cached_path(child).exists() else "not cached"
        if not downloadable(child):
            state = "unavailable to the Web API"
        print(
            f"{child.get('key', '?'):8}  {str(meta.get('contentType') or '?'):<16}  "
            f"{str(meta.get('linkMode') or '?'):<13}  {name}  [{state}]"
        )
    return 0


def cmd_path(args: argparse.Namespace, library: str, key: str) -> int:
    entry = item(args.item, library, key)
    attachment = pdf_attachment(entry, library, key)
    if attachment is None:
        die(f"{args.item} has no PDF attachment")
    path = download(attachment, library, key, refresh=args.refresh)
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


def cmd_doctor(args: argparse.Namespace, library: str, key: str) -> int:
    info = key_info(key)
    access_library = has_permission(info, library, "library")
    access_files = has_permission(info, library, "files")
    print(f"api          {api_base()}")
    print(f"library      {library}")
    print(
        f"key          {info.get('key') or '?'}  "
        f"({info.get('username') or '?'}, user {info.get('userID') or '?'})"
    )
    print(
        f"access       library={access_library} files={access_files} "
        f"write={has_permission(info, library, 'write')}"
    )

    items_path = f"{library_prefix(library)}/items"
    print(f"items        {total_results(items_path, key)}")
    print(f"attachments  {total_results(items_path, key, {'itemType': 'attachment'})}")

    pdfs = 0
    unavailable: list[dict] = []
    seen: set[str] = set()
    for entry in iter_pages(items_path, key, {"itemType": "attachment"}):
        entry_key = entry.get("key", "")
        if entry_key in seen or not is_pdf(entry):
            continue
        seen.add(entry_key)
        pdfs += 1
        if not downloadable(entry):
            unavailable.append(entry)

    files = cache_dir() / "files"
    cached = list(files.glob("*/*")) if files.exists() else []
    size = sum(path.stat().st_size for path in cached if path.is_file())
    print(f"pdf          {pdfs}")
    print(f"cached       {len(cached)} file(s), {size / 1e6:.1f} MB in {files}")

    problems = 0
    for entry in unavailable:
        meta = entry.get("data", {})
        print(f"\nnot stored   {entry.get('key')}  {(meta.get('title') or '')[:60]}")
        print(f"  reason     {unavailable_reason(entry)}")
        print(f"  linkMode   {meta.get('linkMode')}")
        problems += 1

    if access_library is False:
        note("this key cannot read this library; check its permissions at " + KEY_SETTINGS_URL)
        problems += 1
    if access_files is False:
        note("this key cannot download files; enable file access at " + KEY_SETTINGS_URL)
        problems += 1
    if unavailable:
        note(
            "\nThe Web API can only serve files stored in Zotero File Storage. For "
            "linked files, open the item on the computer that holds the file, or "
            "convert the attachment to a stored file."
        )
    if problems:
        return 1
    print("\nok")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("path", help="download the PDF and print its local path")
    p.add_argument("item", help="item key (journal article) or attachment key")
    p.add_argument(
        "--copy-to",
        metavar="DIR",
        help="copy the PDF into DIR under a clean file name and print that path",
    )
    p.add_argument("--refresh", action="store_true", help="download even if cached")
    p.set_defaults(func=cmd_path)

    p = sub.add_parser("attachments", help="list an item's attachments")
    p.add_argument("item", help="item key")
    p.set_defaults(func=cmd_attachments)

    p = sub.add_parser("doctor", help="check the key, the library, and file availability")
    p.set_defaults(func=cmd_doctor)

    p = sub.add_parser("library", help="print the configured library")
    p.set_defaults(func=cmd_library)

    args = parser.parse_args()
    key = resolve_key()
    library = resolve_library(key)
    return args.func(args, library, key)


if __name__ == "__main__":
    sys.exit(main())
