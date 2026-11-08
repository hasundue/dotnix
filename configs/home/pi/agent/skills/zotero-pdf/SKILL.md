---
name: zotero-pdf
description: >
  Find a paper in the Zotero library and get its PDF. Use when the user names a
  paper, author, or topic they expect to be in Zotero, asks for "the paper" or
  "the PDF" without giving a path or URL, or wants the bibliographic metadata
  (title, authors, DOI, abstract) of a Zotero item.
---

# Zotero PDF

> **Status: work in progress.** The Web API half has only been exercised
> against a stub so far, and the previous local-API version against one library.
> When a lookup fails or comes back wrong — an item that exists but is not
> found, metadata that is empty or mismatched, `path` pointing at a missing file
> — **stop the original task**. Say what
> happened, decide with the user how the skill should behave, fix it
> (`scripts/zotero.py` and/or this file), then resume. Reporting a paper as
> unavailable because the lookup was broken is worse than asking.

Two halves, one library:

- **Discovery** — search, metadata, and full text come from the `zotero` MCP
  server (`zotero-mcp`) over the Zotero Web API.
- **The file** — `scripts/zotero.py path` downloads the PDF and prints its
  local path, which is then handed to the `pdf-tools` skill. MCP does not serve
  attachment bytes, and this script does not search.

Nothing here needs a Zotero installation: both halves talk to api.zotero.org.
This skill only _fetches_; extraction, rendering, and reading belong to
`pdf-tools`.

## Discovery (MCP)

The `zotero` server exposes three tools: `zotero_search_items`,
`zotero_item_metadata`, `zotero_item_fulltext`. With the default `codemode`
exposure they are not declared to the model; call them from a script (find them
with `searchTools("zotero")` or `describeNamespace("mcp__zotero")`), and return
only what the task needs:

```js
const res = await tools.mcp__zotero__zotero_search_items({
  query: "Siegert pseudostate",
});
const text = res.content.map((c) => c.text ?? "").join("\n");
text(text);
```

If the server is configured with `direct` exposure, call the tools directly
instead.

- `zotero_search_items` — `{query, qmode?, tag?, limit?}`. `qmode` defaults to
  `titleCreatorYear` (titles, creators, years); pass `qmode: "everything"` to
  also search abstracts, the Extra field, notes, and PDF text. Hits inside a PDF
  or a note come back as child items; the server groups them under their work
  and reports where each match came from, so use its `Key` values as they are.
- `zotero_item_metadata` — `{item_key}`. The complete record (citation key,
  publication details, collections). It does not say whether a PDF exists.
- `zotero_item_fulltext` — `{item_key}`. The text Zotero indexed at sync time,
  not an extraction done here. It also repeats the full metadata in its header.

**Do not dump full text into the conversation.** A paper is 10k-25k tokens.
Either filter inside the codemode script and return only the matching lines:

```js
const res = await tools.mcp__zotero__zotero_item_fulltext({
  item_key: "BH8XS93N",
});
const body = res.content.map((c) => c.text ?? "").join("\n");
const hits = body.split("\n").filter((line) => /Siegert|pseudostate/.test(line));
text(hits.slice(0, 40).join("\n"));
```

or, when figures, tables, equations, or column layout matter, go through
`path` and `pdf-tools` instead.

## The PDF file

```bash
Z=<skill-dir>/scripts/zotero.py
python3 "$Z" path BH8XS93N                     # download if needed, print the path
python3 "$Z" path BH8XS93N --copy-to /tmp/papers  # clean name, e.g. 2007_Batishchev_Title.pdf
python3 "$Z" attachments BH8XS93N              # keys, types, link modes, cache state
python3 "$Z" doctor                            # key, library, file availability
python3 "$Z" library                           # "user:<id>" or "group:<id>"
```

Paths are relative to this skill's directory — resolve `<skill-dir>` from the
directory the harness reports for this skill; never hardcode an absolute path.

Downloads are cached under `~/.cache/zotero-pdf/files/<attachment-key>/` and
reused while the attachment's md5 still matches; `--refresh` forces a new copy.
`path` accepts an item key or an attachment key.

## Workflow

1. **Search** with `zotero_search_items`. Ask for `qmode: "everything"` when the
   term is likely to appear only inside the PDF; keep the default for a
   known-item lookup (author, title, year).
2. **Confirm** with `zotero_item_metadata` when the key is ambiguous — it shows
   the DOI, venue, and abstract that distinguish two similar titles.
3. **Resolve** the PDF with `zotero.py path KEY`. If it exits non-zero, follow
   its message: `doctor` explains whether the key lacks file access or the
   attachment is a linked file.
4. **Read** with `pdf-tools`:

   ```bash
   python3 <pdf-tools-skill-dir>/scripts/pdf.py info "$PDF"
   ```

   `info` decides between text and OCR; `equations` and `figures` isolate
   displays; `text --columns auto` handles two-column layouts.

## Requirements and configuration

The API key needs **library read access and file downloads**. Create one at
<https://www.zotero.org/settings/keys/new>. In dotnix, the key lives in agenix
as `api/zotero`, and `configs/home/pi/zotero.nix` wires it into both halves:

- `~/.config/zotero-pdf/config.json` sets `api_key_file` for this script.
- The `zotero` MCP server is launched through a wrapper that reads the same
  secret and derives `ZOTERO_LIBRARY_ID` from the key, so no numeric ID is
  configured by hand.

Override with environment variables when debugging: `ZOTERO_API_KEY`,
`ZOTERO_API_KEY_FILE`, `ZOTERO_LIBRARY` (`user:<id>` / `group:<id>`),
`ZOTERO_CONFIG`, `ZOTERO_CACHE`, `ZOTERO_API` (base URL).

If Zotero is unreachable or the key is rejected, `zotero.py` exits non-zero with
an explanation: stop and tell the user. Do not silently substitute a web search
— say that the item is not reachable in Zotero and ask whether to look it up
online instead.

## Gotchas

- **Only stored files are downloadable.** `linkMode: linked_file` points at a
  file on the computer that added it, and `linked_url` is a URL, not a file;
  the Web API cannot serve either. `doctor` lists exactly those attachments, so
  ask it before assuming a paper cannot be read. Convert the attachment to a
  stored file, or open it on the computer that holds it.
- **Full text is an index, not an extractor.** `zotero_item_fulltext` returns
  what a Zotero desktop client extracted and synced. A scanned PDF, a file
  added without a desktop client, or an item whose sync has not run yet leaves
  the endpoint at 404 and the tool returns an error string — say so instead of
  treating the paper as empty, and fall back to `path` + `pdf-tools`, which can
  OCR.
- **The Web API does not search citation keys** (the local API does). A query
  that is only a citation key returns nothing; search by title or author, or use
  `qmode: "everything"` for a term from the PDF.
- **Search results include attachment and note hits.** The MCP server groups
  them by work and labels the origin; do not try to fetch a PDF from an
  attachment key of a snapshot (HTML) — `path` resolves the PDF child itself.
- **Read-only.** Items, notes, and annotations cannot be created or edited over
  this API.
- **Not every item has a PDF.** `path` exits non-zero with `no PDF attachment`;
  report that rather than searching the filesystem for look-alike files.
