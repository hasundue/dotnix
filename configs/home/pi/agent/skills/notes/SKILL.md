---
name: notes
description: >
  Capture, find, and maintain notes in the user's Obsidian vault at ~/notes.
  Use when the user asks to save, record, write up, or keep part of the
  conversation as a note for later; when they ask what they already know about a
  topic, or want an existing note found, read, or updated; and for decisions,
  research summaries, and ideas that should outlive the session without living
  in a repository. Not for scratch files inside a repository.
---

# Notes

The vault is a reading surface, not a log sink. Every note should be worth
opening cold, weeks later, by someone who was not in the conversation.

## Modes

Decide before acting; almost every request is one of two.

- **capture** -- persist something from the conversation: a decision, a
  discussion, a piece of research, an idea. Write a new note, or append to the
  existing one.
- **recall** -- read what is already there: find a note, answer from the vault,
  check whether a topic is covered. Search, read the best hits, report the paths
  and what they say.

Maintenance (append, link, rename, mark done) belongs to whichever mode asked
for it.

## Search before writing

Never create a note blind. Look for the topic first:

```sh
cd ~/notes
rg -l -i '<terms>' .
fd -e md . | rg -i '<slug words>'
```

Hidden directories (`.stversions/`, `.obsidian/`) are skipped by `rg` and `fd`
by default. Do not add `-u` to reach into them.

Title and body matches mean different things:

- **Same topic, same task** -- append. Do not fork a second note.
- **Same topic, different angle** -- new note, linked from the new side.
- **Nothing** -- new note.

When the hits are close but you cannot tell, ask: "append to `X`, or start a new
note?" That is the one question worth interrupting for.

## Choosing the path

| What it is                            | Where                  | Filename                    |
| ------------------------------------- | ---------------------- | --------------------------- |
| Work, decision, or research in a repo | `projects/<project>/`  | `YYYY-MM-DD-<slug>.md`      |
| Third-party OSS or library research   | `oss/<repo>/research/` | `<slug>.md`                 |
| OSS issue write-up                    | `oss/<repo>/issues/`   | `<slug>.md`                 |
| Idea or concept worth keeping         | `ideas/<domain>/`      | `<slug>.md`                 |
| Fiction                               | `sf/<work>/`           | append to the existing file |

Rules:

- A path the user gave wins over every rule here.
- Resolve `<project>` from git, so worktrees land on the main checkout:
  ```sh
  basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
  ```
- `<domain>` and `<repo>` are existing directories. List them before choosing:
  ```sh
  fd -t d -d 2 . ~/notes
  ```
  If nothing fits, **ask** before creating a top-level directory.
- `<slug>` is ASCII kebab-case derived from the note, under about 50 characters.
  The `#` title carries the readable, possibly non-ASCII, name.
- There is no `inbox/`. A note with no home is a question, not a file.

## Distilling

A note is not a transcript. Write what a cold reader needs:

- the question or problem, in one short section
- what was decided, and why -- a decision without its reason gets re-litigated
- what is still open, if anything
- the user's own words, verbatim and in quotes, where the phrasing carries
  intent; a paraphrase goes in prose, never in quotes
- concrete paths, commands, versions, links -- not "the usual config"

Drop tool chatter, dead ends that taught nothing, and anything the reader can
recompute. If the conversation reached no conclusion, the note records the
options and why none was taken.

## Writing

Frontmatter, minimal:

```yaml
---
created: <YYYY-MM-DD>
source: <repo> @ <branch>   # optional: repo, branch, URL, or session
tags: []
---
```

Leave `tags` empty unless the tag already exists in the vault; check with
`rg --no-filename '^tags:' . | sort -u` before inventing one.

Body shape follows the note's language -- `references/templates.md` holds the
heading sets for Japanese and English, and the shapes for capture, research, and
idea.

Two rules override taste:

- **Append, do not rewrite.** Existing text is not reformatted, reordered, or
  reworded. An append starts with a dated `##` heading and goes at the end.
- **Leave alone what you did not write.** A note that already carries `status:`,
  `confirmed:`, or a branch record is maintained by another workflow; add to the
  body, leave its frontmatter as it is.

Language follows the conversation: a Japanese discussion gets a Japanese note.
This is the explicit exception to the repository rule that files are written in
English -- the vault is user content, not source.

## Reporting

After writing, say what landed, in one short block:

```
~/notes/projects/<project>/<YYYY-MM-DD>-<slug>.md
  One line on what the note says
  linked: [[<related note>]]
```

Path, one line on what the note says, and what it links to. Do not paste the
note back unless asked.

## Recall

Search, then read. Do not answer from filenames alone.

```sh
cd ~/notes
rg -l -i '<terms>' .
rg -n -i '<terms>' . | head -40
```

Report the path, one line per note on what it says, and the quote or section
that answers the question. If several notes disagree, say so and give dates --
the newer one usually wins, and the disagreement is worth knowing.

Zero hits is an answer: say nothing is there, and offer to write the note that
should have existed.

## Hands off

- `.obsidian/`, `.stfolder/`, `.stversions/` -- Obsidian and Syncthing state
- `*.sync-conflict-*` -- report it, do not merge or delete
- Notes outside the request: no retroactive edits to make links resolve. An
  outgoing `[[link]]` is enough; Obsidian shows the backlink.
- `rpiv/` -- legacy artifacts, read-only unless the user says otherwise

## Red flags

- Creating a note without searching first
- A second note for a topic that already has one
- Inventing a top-level directory or tag, or editing frontmatter you did not
  write
- Transcript pasted into the vault, or tool output left in it
- Rewriting existing prose instead of appending
- A paraphrase inside quotation marks
- Editing `.stversions/` or a sync-conflict file
- Reporting "saved" without the path

## Verification

- [ ] Searched the vault before writing
- [ ] Path follows the table, or the user's path
- [ ] Frontmatter has `created`; tags only if they already exist
- [ ] Headings follow `references/templates.md`, in the note's language
- [ ] User quotes are verbatim; no transcript dump
- [ ] Existing notes were appended to, never rewritten
- [ ] Frontmatter of existing notes was left untouched
- [ ] The reply names the path and what the note says
