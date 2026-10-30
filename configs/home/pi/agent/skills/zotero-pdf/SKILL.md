---
name: zotero-pdf
description: >
  Find a paper in the local Zotero library and get its PDF. Use when the user
  names a paper, author, or topic they expect to be in Zotero, asks for "the
  paper" or "the PDF" without giving a path or URL, or wants the bibliographic
  metadata (title, authors, DOI, abstract) of a Zotero item.
---

# Zotero PDF

> **Status: work in progress.** This skill has only been exercised against one
> library and one Zotero version. When a lookup fails or comes back wrong — an
> item that exists but is not found, metadata that is empty or mismatched,
> `path` pointing at a missing file, `start`/`stop` leaving a stray process —
> **stop the original task**. Say what happened, decide with the user how the
> skill should behave, fix it (`scripts/zotero.py`, and this file), then resume.
> Reporting a paper as unavailable because the lookup was broken is worse than
> asking.

Resolve a paper to a local PDF through Zotero's read-only local API, then hand
the file to the `pdf-tools` skill to read it. This skill only _fetches_;
extraction and rendering belong to `pdf-tools`.

```bash
Z=<skill-dir>/scripts/zotero.py
python3 "$Z" search "Siegert pseudostate"      # key, year, type, author, title
python3 "$Z" info BH8XS93N                     # metadata, abstract, PDF status
python3 "$Z" path BH8XS93N                     # local PDF path
python3 "$Z" doctor                            # attachments whose file is not on disk
```

Paths are relative to this skill's directory — resolve `<skill-dir>` from the
directory the harness reports for this skill; never hardcode an absolute path.

## Starting Zotero

Zotero does not have to be open. `--headless` runs it with no window (warm start
is about 2 s, a cold profile up to a minute):

```bash
python3 "$Z" start        # `zotero --headless`, waits for the API, then returns
python3 "$Z" stop         # stops the instance this script started
ZOTERO_AUTOSTART=1 python3 "$Z" search "Siegert"   # start on demand
```

Opening the Zotero window afterwards attaches it to the running instance, so the
headless process can be left alone. If you prefer the GUI, just run Zotero
normally and set `ZOTERO_AUTOSTART` unset or `0`.

**A running GUI is fine.** `start` (and `ZOTERO_AUTOSTART`) first probes the
API: with the GUI up and the local API enabled it prints "already reachable" and
does nothing. If a Zotero process exists but answers `403` (local API switched
off), it refuses to launch a second instance and tells you to enable the setting
— a second launch on the same profile would only open a window or die on the
lock.

Environment overrides: `ZOTERO_CMD` (default `zotero --headless`), `ZOTERO_LOG`
(default `/tmp/zotero-headless.log`).

## Requirements

Zotero 7 must be running with **Settings → Advanced → "Allow other applications
on this computer to communicate with Zotero"** enabled, and the PDF must already
be stored (synced or downloaded) in the library. The script uses only the Python
standard library.

If Zotero is unreachable, `zotero.py` exits non-zero with an explanation: stop
and tell the user. Do not silently substitute a web search — say that the item
is not reachable in Zotero and ask whether to look it up online instead.

## Workflow

1. **Search** — `search QUERY` prints `KEY  YEAR  TYPE  FIRSTAUTHOR  TITLE`. Use
   `--mode titleCreatorYear` for a focused search, `--limit` to widen it,
   `--json` for structured output.
2. **Confirm** — `info KEY` shows title, authors, date, venue, DOI, URL, the
   abstract, and whether a PDF is attached (`pdf ... [attachment-key, ok]`).
3. **Resolve** — `path KEY` prints the PDF path. Pass an attachment key too if
   the user gives one. `--copy-to DIR` copies it under a clean name
   (`2007_Batishchev_Title.pdf`) which is convenient when a shell pipeline
   chokes on the spaces and percent-escapes of Zotero's own filenames.
4. **Read** — switch to `pdf-tools` with that path:

   ```bash
   python3 <pdf-tools-skill-dir>/scripts/pdf.py info "$PDF"
   ```

   `info` decides between text and OCR; `equations` and `figures` isolate
   displays; `text --columns auto` handles two-column layouts.

## Gotchas

- **Do not try to download the bytes.** The API answers `/items/<KEY>/file` with
  a 302 and no body. `links.enclosure.href` in the item metadata is the only
  route to the file, which is what `path` prints.
- **Zotero filenames are URL-encoded and full of spaces.** `path` decodes them;
  quote the result, or use `--copy-to` when another tool will consume it.
- **Search results exclude attachments.** Zotero matches attachment titles too,
  so a query like `PDF` returns the papers those attachments belong to; when you
  already hold an attachment key, pass it straight to `path`.
- **Read-only.** Items, notes, and annotations cannot be created or edited; the
  local API is a reader. Full-text search inside PDFs (`/fulltext`) is
  unreliable in practice (it has returned 404), so search metadata instead, then
  grep the extracted text with `pdf-tools`.
- **Items saved by the browser connector are readable immediately.** The
  connector hands the file to the running Zotero client, which writes it into
  `storage/<ITEMKEY>/` at save time — opening the item is not required. Files
  are only absent when the item arrived from another device or from zotero.org
  and sync has not fetched it yet, which happens with **Settings → Sync →
  "Download files as needed"** enabled. `doctor` lists exactly those attachments
  (and any `linked_file` whose target vanished), so ask it before assuming a
  paper cannot be read.
- **Not every item has a PDF.** `info` prints `pdf none (<reason>)`; report that
  rather than searching the filesystem for look-alike files.
