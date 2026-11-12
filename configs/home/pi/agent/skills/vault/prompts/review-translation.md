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

## Scope

The caller guarantees the mechanical half before calling: front matter,
headings, criteria, code spans, untranslated prose, quotations, and
heading references already match. Do not re-derive them. Your job is only
what no script settles, listed under Compare. If you happen to spot a
mechanical break the script missed, report it as a finding anyway.

## Compare

Compare the pair directly, both files read in full. The script has settled
the mechanical half; yours to decide by reading:

- the problem still states the same problem: a translation that reads
  better but says something else is a finding, not an improvement
- the prose reads as a translation rather than an improvement
- restatements carry the same content, attributed: a restatement that
  quotes the user is a finding
- the log carries one entry for one: evidence, not prose to polish

A translation that merges, drops, or improves is not a translation. Treat every
departure as a finding, however good the prose.

## Report

In the language of this conversation, list each finding with both file paths and
line numbers, the draft text, the candidate text, and which rule above it
breaks. Order them by severity: a mechanical break the script missed,
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
