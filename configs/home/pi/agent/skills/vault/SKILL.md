---
name: vault
description: >
  Read and maintain the user's Obsidian vault at `~/vault`: find what is already
  there, answer from it, and write durable notes -- decisions, research,
  handoffs -- where their subject lives. Use when the user asks what they
  already know about a topic, wants a note found, read, or updated, or wants a
  decision or a piece of research written up. Conventions shared by every note
  are in `references/conventions.md`; fragments belong to `ditty`, and task
  notes to `keel` and `sail`.
---

# Vault

Three kinds of notes share `~/vault`, and they are not held to the same
standard.

- **Durable notes** must survive a cold read: decisions, research, handoffs.
  This skill writes them.
- **Working notes** are fragments to think with. `ditty` owns them.
- **Task notes** (`projects/<project>/`, carrying `status`) are `keel`'s and
  `sail`'s.

`references/conventions.md` holds what binds all three: paths, filenames,
languages, ownership, quotes. Read it before writing or renaming anything; the
rules are not restated here.

## Modes

Decide before acting; almost every request is one of two.

- **capture** -- persist something durable from the conversation: a decision, a
  discussion, a piece of research. Write a new note, or append to one this skill
  wrote.
- **recall** -- read what is already there: find a note, answer from the vault,
  check whether a topic is covered. Search, read the best hits, report the paths
  and what they say.

Maintenance (append, link, rename, mark done) belongs to whichever mode asked
for it.

## Ownership

The rule is in `references/conventions.md`; in practice you create freely, edit
only notes carrying `author: pi`, and never touch a person's note without an
explicit request. List what the skills wrote:

```sh
rg --files-with-matches '^author: pi' ~/vault
```

## Search before writing

Never create a note blind. Look for the topic first:

```sh
cd ~/vault
rg -l -i '<terms>' .
fd -e md . | rg -i '<slug words>'
```

Hidden directories (`.stversions/`, `.obsidian/`) are skipped by `rg` and `fd`
by default. Do not add `-u` to reach into them.

Title and body matches mean different things:

- **Same topic, same task** -- append if the note is yours, otherwise link it.
- **Same topic, different angle** -- new note, linked from the new side.
- **Nothing** -- new note.

When the hits are close but you cannot tell, ask: "append to `X`, or start a new
note?" That is the one question worth interrupting for.

Before appending, read the tail of the note. You are continuing it, and its
shape is the one that applies.

## Writing durable notes

Written for a reader who was not in the conversation, or for the author in a
month: decisions, research, handoffs.

Frontmatter:

```yaml
---
author: pi
created: <YYYY-MM-DD>
source: <repo> @ <branch> # optional: repo, branch, URL, or session
tags: []
---
```

`tags` stays empty unless the tag already exists in the vault; check with
`rg --no-filename '^tags:' . | sort -u`.

Shape follows the note's language. `references/templates.md` holds the heading
sets for Japanese and English, and the shapes for capture and research notes.

Distill, do not transcribe:

- the question or problem, in one short section
- what was decided, and why -- a decision without its reason gets re-litigated
- what is still open, if anything
- concrete paths, commands, versions, links -- not "the usual config"

Drop tool chatter, dead ends that taught nothing, and anything the reader can
recompute. If the conversation reached no conclusion, the note records the
options and why none was taken.

## Appending

Append; never rewrite. Existing text is not reformatted, reordered, or reworded.

A durable note takes a dated `## <YYYY-MM-DD>` heading at the end. Never add
frontmatter to a note that has none, and never change `author:` to claim a note.

## Reporting

After writing, say what landed: the path, what the note says, and what it links
to. Do not paste the note back unless asked.

## Recall

Search, then read. Do not answer from filenames alone.

```sh
cd ~/vault
rg -l -i '<terms>' .
rg -n -i '<terms>' . | head -40
```

Report the path, what each note says, and the quote or section that answers the
question. If several notes disagree, say so and give dates -- the newer one
usually wins, and the disagreement is worth knowing.

Zero hits is an answer: say nothing is there, and offer to write the note that
should have existed. A fragment belongs in `ditty`, a written-up answer here.

## Hands off

- `.obsidian/`, `.stfolder/`, `.stversions/` -- Obsidian and Syncthing state
- `*.sync-conflict-*` -- report it, do not merge or delete
- Notes outside the request: no retroactive edits to make links resolve. An
  outgoing `[[link]]` is enough; Obsidian shows the backlink.

## Red flags

- Creating a note without searching first
- A second note for a topic that already has one
- Editing a note that does not carry `author: pi`
- Inventing a top-level directory or tag
- Pasting a transcript into the vault, or leaving tool output in it
- Rewriting existing prose instead of appending
- A paraphrase inside quotation marks
- Editing `.stversions/` or a sync-conflict file
- Reporting "saved" without the path
- Writing a fragment as a durable note, or a durable note as a fragment

## Verification

Mark an item N/A rather than ticking it when it does not apply. A tick that was
never earned hides the failure.

- [ ] Searched the vault before writing
- [ ] Path and filename follow `references/conventions.md`, or the user's path
- [ ] The new note carries `author: pi`; existing `author:` was left alone
- [ ] A person's note was edited only on an explicit request
- [ ] Headings follow `references/templates.md`, and the note's language
- [ ] Appended: the diff is the added lines and nothing else
- [ ] User quotes are verbatim; no transcript dump
- [ ] The reply names the path and what the note says
