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

Two kinds of notes share this vault, and they are not held to the same standard.
A note meant for someone else has to survive being read cold; a note meant for
its author is a workbench and may be a fragment. The standard follows the note,
not your preference for structure.

## Modes

Decide before acting; almost every request is one of two.

- **capture** -- persist something from the conversation: a decision, a
  discussion, a piece of research, an idea. Write a new note, or append to one
  this skill wrote.
- **recall** -- read what is already there: find a note, answer from the vault,
  check whether a topic is covered. Search, read the best hits, report the paths
  and what they say.

Maintenance (append, link, rename, mark done) belongs to whichever mode asked
for it.

## Ownership

`author: pi` marks a note this skill wrote. A note without it was written by a
person.

- Create freely. Edit only a note that carries `author: pi`.
- A person's note is read-only. To add to its topic, write a new note and link
  it with `[[<note>]]`.
- Only an explicit request ("add this to that note") overrides that: append in
  the note's existing shape, and never touch its `author:`.
- List everything this skill has written:
  `rg --files-with-matches '^author: pi' ~/notes`

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

- **Same topic, same task** -- append if the note is yours, otherwise link it.
- **Same topic, different angle** -- new note, linked from the new side.
- **Nothing** -- new note.

When the hits are close but you cannot tell, ask: "append to `X`, or start a new
note?" That is the one question worth interrupting for.

Before appending, read the tail of the note. You are continuing it, and its
shape is the one that applies.

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
  The `#` title carries the readable, possibly non-ASCII, name -- where the note
  has a title at all.
- There is no `inbox/`. A note with no home is a question, not a file.

## Writing

### Durable notes

Written for a reader who was not in the conversation, or for the author in a
month: decisions, research, handoffs. `projects/` and `oss/` hold these.

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
- the user's words, verbatim and in quotes, where the phrasing carries intent; a
  paraphrase goes in prose, never in quotes
- concrete paths, commands, versions, links -- not "the usual config"

Drop tool chatter, dead ends that taught nothing, and anything the reader can
recompute. If the conversation reached no conclusion, the note records the
options and why none was taken.

### Working notes

`ideas/` and `sf/` are workbenches: notes to think with, read by their author
days later. They are allowed to be fragments -- a bullet, a question, a name, a
sentence with no verb.

- No headings, no summary, no `## Related`, no tags. `author: pi` is the only
  frontmatter.
- Under about five lines, do not add structure. If it feels too short to stand
  alone, that is correct.
- State the idea, not its justification. Wanting to explain why it matters is a
  signal to ask a question instead of writing a paragraph.
- Keep the note's own habits: tab-indented bullets stay tab-indented, an inline
  `#sf #idea` stays inline.

### Appending

Append; never rewrite. Existing text is not reformatted, reordered, or reworded.

- Durable note: a dated `## <YYYY-MM-DD>` heading at the end.
- Working note: one more line in the shape of the lines above it. No heading, no
  introduction, no summary of what is already there.
- Never add frontmatter to a note that has none, and never change `author:` to
  claim a note.

Language follows the conversation: a Japanese discussion gets a Japanese note.
This is the explicit exception to the repository rule that files are written in
English -- the vault is user content, not source.

## Reporting

After writing, say what landed: the path, what the note says, and what it links
to. Do not paste the note back unless asked.

## Recall

Search, then read. Do not answer from filenames alone.

```sh
cd ~/notes
rg -l -i '<terms>' .
rg -n -i '<terms>' . | head -40
```

Report the path, what each note says, and the quote or section that answers the
question. If several notes disagree, say so and give dates -- the newer one
usually wins, and the disagreement is worth knowing.

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
- Editing a note that does not carry `author: pi`
- Inventing a top-level directory or tag
- Adding headings, a summary, or a "related" section to a note that had none
- Explaining why an idea matters instead of writing the idea
- Promoting a fragment into a durable note without being asked
- Transcript pasted into the vault, or tool output left in it
- Rewriting existing prose instead of appending
- A paraphrase inside quotation marks
- Editing `.stversions/` or a sync-conflict file
- Reporting "saved" without the path

## Verification

Mark an item N/A rather than ticking it when it does not apply. A tick that was
never earned hides the failure.

- [ ] Searched the vault before writing
- [ ] Path follows the table, or the user's path
- [ ] The new note carries `author: pi`; existing `author:` was left alone
- [ ] A person's note was edited only on an explicit request
- [ ] Durable note: headings follow `references/templates.md`, frontmatter has
      `created`
- [ ] Working note: no headings, no summary, no tags, no justification
- [ ] Appended to a working note: the diff is the added lines and nothing else
- [ ] User quotes are verbatim; no transcript dump
- [ ] The reply names the path and what the note says
