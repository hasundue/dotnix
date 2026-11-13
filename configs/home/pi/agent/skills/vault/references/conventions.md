# Vault conventions

Every note in `~/vault` follows these, whichever skill writes it. They are the
only copy: `vault`, `ditty`, `keel`, and `sail` read this file instead of
restating it.

`<note>` below is a file name without its extension -- `<YYYY-MM-DD>-<slug>` for
a project note, `<slug>` elsewhere. `<slug>` is ASCII kebab-case derived from
the note, under about 50 characters; the `#` title carries the readable,
possibly non-ASCII, name, where the note has a title at all.

## Where a note lives

One location is load-bearing enough to be named here: `projects/<project>/`,
where task notes and repo work live, because keel and sail search for them
there. Resolve `<project>` from git, so worktrees land on the main checkout:

```sh
basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
# ~/dotnix.pi-workflow -> dotnix
```

Every other location is read from the live tree, because a hardcoded map
drifts:

```sh
fd -t d -d 2 . ~/vault
```

- A path the user gave wins over every rule here.
- A durable note lives with its subject, in the directory the vault already
  keeps for it. Ask before creating a top-level directory.
- A fragment lives in a fragment directory. Some hold one file per thought;
  some hold one file per work and take appends. Read the directory and follow
  its habit.
- There is no `inbox/`. A note with no home is a question, not a file.

## Names and languages

| File               | Means                                              |
| ------------------ | -------------------------------------------------- |
| `<note>.md`        | the note, in English                               |
| `<note>.<lang>.md` | the same note in another language, e.g. `.ja.md`   |
| `<note>.en.md`     | an English candidate, only while its check is open |

The vault is user content, not source: a note in Japanese stays Japanese, and
the repository rule that files are written in English does not reach here. A
note that is not in English carries its language in the name for as long as it
lives.

Nothing is retrofitted. The vault's Japanese archive is history, not a migration
backlog; the rule covers notes written from now on, and notes someone actually
reopens.

Task notes are the exception. They are agreed with someone and then executed by
a cold session, so they end up English.

## A task note's language lifecycle

A draft is argued over in the session's language, with `session_lang:` in its
front matter so a cold session knows which tongue to report in. Approval turns
it into the English record, once, in place.

1. Translate into `<note>.en.md`, next to the draft. The boundary is mechanical:
   inside a code span or a fence is code, copied byte for byte; everything else
   is prose, translated. That includes a `verify:` step written as a sentence --
   "the table in the results note shows ..." is prose. A mention of this note's
   own heading moves with the heading, even inside backticks, and no line may
   point at a heading the translation renamed. Keep one heading, one criterion,
   one log entry for one; a translation that merges, drops, or improves is not a
   translation.

   Before handing the pair over, run
   `~/.pi/agent/skills/vault/scripts/check_pair.py <draft>`. It is the
   translator's own pre-flight: the rules below, executable. Fix what it
   reports; a clean run does not mean the pair is checked.

2. Let another agent check the pair. The model, and optionally the thinking level, should be
   specified by user instructions or project conventions. Ask if unsure:

   ```sh
   ~/.pi/agent/skills/subagent/scripts/run.py \
     --model MODEL \
     --prompt ~/.pi/agent/skills/vault/prompts/review-translation.md -- \
     @DRAFT @CANDIDATE
   ```

   If the check fails, fix the candidate in place, re-run `check_pair.py`
   on the draft, and re-check the pair in full with the same run:

   ```sh
   ~/.pi/agent/skills/subagent/scripts/run.py --resume -- \
     "Re-check @CANDIDATE against @DRAFT in full."
   ```

   A failed check is fixed and re-run once, then ask the user: do not grind
   through re-checks without them.

   Anything that fails is fixed before the promotion, not after.

3. Promote: `status: agreed`, `translated: <YYYY-MM-DD>`, rename
   `<note>.en.md` to `<note>.md`, delete the draft. The original does not
   survive: a note that exists twice is a note whose wording drifts.

From approval on the note is English for life, log entries and blockers
included. A draft that is already English needs only step 3.

While the check is open, `<note>.ja.md` and `<note>.en.md` are one note, not
two. Discovery finds both; treat the pair as one hit.

## Ownership

`author: pi` marks a note a skill wrote. A note without it was written by a
person.

- Create freely. Edit only a note that carries `author: pi`.
- A person's note is read-only. To add to its topic, write a new note and link
  it with `[[<note>]]`.
- Only an explicit request ("add this to that note") overrides that: append in
  the note's existing shape, and never change `author:` to claim a note.
- Task notes under `projects/<project>/` are keel's and sail's: they carry
  `status` instead of `author:`, and their owner is the session that agreed
  them.
- List everything the skills have written:
  `rg --files-with-matches '^author: pi' ~/vault`

## Deleting and moving notes

Use the Obsidian CLI, never `rm` or `mv`, to delete, rename, or move a note.
The CLI asks the running Obsidian app to perform the operation, so
`Automatically update internal links` rewrites `[[wikilink]]` targets. A raw
filesystem change leaves the old link text behind as an unresolved link.

```sh
obsidian backlinks file=<note>           # who points at it
obsidian delete file=<note>              # trash by default (~/vault/.trash/)
obsidian move file=<note> to=archive/    # rename and move; links follow
obsidian rename file=<note> name=<new>   # rename in place; links follow
obsidian unresolved verbose              # verify afterwards
```

Run these from `~/vault`, or put `vault=<name>` before the command; otherwise
the CLI targets whichever vault is active. `delete` without `permanent` is the
only form with recovery; `permanent` needs an explicit request from the user.
If the CLI is unavailable, leave the note in place instead of deleting it, or
fix the referring links by hand.

The CLI updating links as part of an operation is not a retroactive edit to
another note. A person's note is still read-only under Ownership above.

## What the user said

Vault notes quote sparingly and exactly: the user's words stay verbatim inside
quotation marks, in the language they were spoken in, wherever that differs from
the note's. A paraphrase goes in prose, never in quotes.

Task notes are the stronger case, and the opposite one: they restate, never
quote. A task note is the agreement, not the conversation, and a translated
quotation is neither a quote nor a statement. Attribute the content instead --
"the user ruled out X because Y" -- and let criteria and decisions carry the
binding form.
