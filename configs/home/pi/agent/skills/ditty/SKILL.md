---
name: ditty
description: >
  Capture a fragment in the user's Obsidian vault -- an idea, a question, a
  name, a line of thought -- or extend one that is already there. Use when the
  user says to jot something down, when a thought should outlive the session
  without becoming a written-up note, or when what they said plainly belongs to
  a fragment that exists. Decisions and research written up for a reader are
  `vault`; task notes are `keel` and `sail`.
---

# Ditty

A fragment, not a note: a bullet, a question, a name, a sentence with no verb.
The reader is the author, days later. Being readable cold is not the standard
here, and adding structure to compensate is a regression.

Read `../vault/references/conventions.md` before writing: where a fragment
lives, what it is called, its language, and who may edit it. This skill is only
about the shape.

## Search first

A fragment that already exists gets a line, not a second file:

```sh
cd ~/notes
rg -l -i '<terms>' .
fd -e md . | rg -i '<slug words>'
```

A hit that has headings, or frontmatter beyond `author: pi`, is a durable note
or a task note -- not a fragment. Leave it alone. If a hit is close but not the
same thought, ask: "add to `X`, or start a new one?"

## Shape

- No headings, no summary, no `## Related`, no tags. `author: pi` is the only
  frontmatter.
- Under about five lines, do not add structure. If it feels too short to stand
  alone, that is correct.
- State the idea, not its justification. Wanting to explain why it matters is a
  signal to ask a question instead of writing a paragraph.
- Keep the note's own habits: tab-indented bullets stay tab-indented, an inline
  `#sf #idea` stays inline.

## Appending

Read the tail first, then add one more line in the shape of the lines above it.
No heading, no introduction, no summary of what is already there. Existing text
is not reformatted, reordered, or reworded.

## Hands off

- Anything with a shape -- headings, or frontmatter beyond `author: pi`. It is
  a `vault` write-up or a `keel`/`sail` task note, not a fragment.
- `.obsidian/`, `.stfolder/`, `.stversions/` -- Obsidian and Syncthing state
- `*.sync-conflict-*` -- report it, do not merge or delete
- `rpiv/` -- legacy artifacts, read-only unless the user says otherwise

## Red flags

- Adding a heading, a summary, or a "related" section to a fragment
- Promoting a fragment into a durable note without being asked
- A second file for a fragment that already exists
- Explaining why an idea matters instead of writing the idea
- Rewriting the lines above instead of appending
- Editing a fragment that does not carry `author: pi`

## Verification

- [ ] Searched the vault for an existing fragment first
- [ ] Path and filename follow `../vault/references/conventions.md`
- [ ] No headings, no summary, no tags, no justification
- [ ] Appended: the diff is the added lines and nothing else
- [ ] The reply names the path and what it now says
