# Note shapes

Three shapes cover what the vault holds. Pick one, then use the heading set for
the note's language. Headings are load-bearing: a note is found by reading its
shape, not by remembering where it went.

## Heading sets

| Shape    | Japanese                          | English                                                     |
| -------- | --------------------------------- | ----------------------------------------------------------- |
| capture  | 概要 / 議論 / 決定 / 未決 / 関連  | Summary / Discussion / Decisions / Open questions / Related |
| research | 問い / わかったこと / 出典 / 関連 | Question / Findings / Sources / Related                     |
| idea     | freeform                          | freeform                                                    |

Use only the sections that have content. A `## 決定` with nothing under it is
worse than no `## 決定`; the reader cannot tell "not decided" from "not filled
in". Record the absence in prose under 概要 instead.

## capture

A conversation that reached a conclusion, or narrowed to a choice.

```markdown
---
created: <YYYY-MM-DD>
source: <repo> @ <branch>
tags: []
---

# <title>

## 概要

<What this is about and why it is worth keeping. Two to four sentences.>

## 議論

<Options considered, trade-offs, dead ends that taught something. Omit when the
answer was obvious.>

## 決定

- <decision> -- <reason>

## 未決

- <open question> -- <what would settle it>

## 関連

- [[<existing note>]] -- <why it is related>
```

## research

Something was looked up and the answer should survive the session.

```markdown
---
created: <YYYY-MM-DD>
source: <url or repo>
tags: []
---

# <title>

## 問い

<The question, specific enough to be answered.>

## わかったこと

<The answer, then the evidence for it. Numbers, versions, paths.>

## 出典

- <url> -- <what it establishes>
- `<path>` -- <what it shows>

## 関連

- [[<existing note>]] -- <why>
```

Sources are not decoration: a claim without one is a guess that will be trusted
later.

## idea

A seed. No template -- freeform, as long as the first lines say what the thing
is and what makes it interesting. Only `created` in the frontmatter. If the idea
has grown into work with a goal, say so instead of filing it as an idea.

## Appending

Appends go at the end of the note, under a dated heading:

```markdown
## <YYYY-MM-DD>

<What changed, or what was added. Link the new material if it lives elsewhere.>
```

Never edit the frontmatter to reflect an append -- `created` is the creation
date. Never renumber or reorder earlier sections.

## Filled example

Illustrative: the prose shows the register and the level of detail. Identifiers
that would point at real things -- the repository, the branch, the linked notes
-- are placeholders.

```markdown
---
created: 2026-11-05
source: <repo> @ <branch>
tags: []
---

# Notes skill: capture and recall in the vault

## 概要

A pi skill for reading and writing the Obsidian vault at `~/notes`, so a
discussion can be persisted and found again without the user copying it by hand.
The vault had drifted into a write-only store: five top-level directories, two
filename conventions, and almost no links between notes.

## 議論

Two modes in one skill, or one skill each. Separate skills would keep each
description narrow, but recall would then be invisible at the moment it is
needed -- when the user asks what they already know. Keeping them together costs
context and risks the skill triggering on any mention of a note.

A static directory map would drift. Reading the taxonomy at runtime with
`fd -t d -d 2` costs one command and stays true.

## 決定

- capture and recall in one skill -- recall is what makes writing worth doing
- paths resolved from the live tree, not a hardcoded map -- the map was already
  stale in two places
- `inbox/` rejected -- an unclear destination is a question worth asking, and a
  catch-all folder hides the ambiguity
- no `type:` field yet -- Bases views can come later, once the shapes settle

## 未決

- whether task notes and everything else should share `projects/`, or split

## 関連

- [[<related note>]] -- <why it is related>
```
