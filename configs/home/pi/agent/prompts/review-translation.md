---
description: Check a task note's draft against its English candidate
argument-hint: "[path to the draft or the .en.md candidate]"
---

Check the translation pair named in `$@`. You are the party who did
not translate it: your job is the check in
`~/.pi/agent/skills/vault/references/conventions.md`, step 2 of "A task note's
language lifecycle". Read that section first.

Review only. Do not edit either file, do not promote, do not change `status:`.
Report findings and stop; fixing and promotion are someone else's call.

## Find the pair

- An `.en.md` path is the candidate; its sibling `<note>.<lang>.md` is the
  draft.
- A `<note>.<lang>.md` path is the draft; the candidate is `<note>.en.md`.
- No argument: search `~/vault/projects/<project>/` for `*.en.md` with an open
  check, resolve `<project>` from git as the skills do, and ask which one if
  several exist.

If there is no candidate, there is no open check: say so and stop. If either
file of the pair is missing, say which one and stop.

## Run the checker

Run `~/.pi/agent/skills/vault/scripts/check_pair.py <draft>`. It compares front
matter, headings, criteria, code, untranslated prose, quotations, and heading
references, and exits non-zero on any finding. Treat its output as facts: cite
what it flags rather than re-deriving it by hand. When checker output is
appended at the end of this prompt, that is the run's output -- use it and do
not re-run anything yourself. When nothing is appended and you have no shell
to run it, stop and report that the check needs the pair's checker output;
do not guess at what it would have said.

## Compare

Compare the pair directly, both files read in full. Report findings by the
conventions' own list:

- every heading present, in order, none merged or dropped
- every acceptance criterion present: same count, same order, same
  `[ ]` / `[x]` / `unmet:` state
- code identical character for character: commands, paths, identifiers,
  versions, numbers, and the contents of every backtick and fence. A command
  that greps for Japanese labels stays Japanese; code the translation "fixed"
  is a finding
- prose translated, `verify:` steps written as sentences included. A verify
  that still reads Japanese is an untranslated note, not a faithful copy
- references resolve: a mention of the note's own heading or criterion moved
  with its target, backticked or not, and no line points at a heading the
  translation renamed. Code that would break because a heading moved is
  reported, never rewritten
- no quotation of the user anywhere: restatements carry the same content,
  attributed
- the problem still states the same problem: a translation that reads better
  but says something else is a finding, not an improvement
- the log translated one entry for one: evidence, not prose to polish

A translation that merges, drops, or improves is not a translation. Treat every
departure as a finding, however good the prose.

The script settles the bullets it can. The rest are yours to decide by reading:
whether the problem still states the same problem, whether the prose reads as a
translation rather than an improvement, whether a restatement quotes, and
whether the log carries one entry for one.

## Report

In the language of this conversation, list each finding with both file paths and
line numbers, the draft text, the candidate text, and which rule above it
breaks. Order them by severity: code changed, criterion or heading lost,
meaning changed, then style. If a category has no findings, one line saying so
is enough; do not narrate clean comparisons.

End with one verdict line, exactly one of these two, as the last line:

```
VERDICT: promotable
```

```
VERDICT: not-promotable
```

- `VERDICT: promotable` -- the pair is a faithful translation, and promotion
  is translate -> check -> promote with the draft deleted
- `VERDICT: not-promotable` -- the findings must be fixed first, and the
  candidate must be rechecked after

The verdict line is machine-read: no rewording, no extra verdict lines.
Neither verdict edits anything, and neither asks whether to go ahead. The next
move is the user's.
