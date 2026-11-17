# Translation check

Your task is the independent check of a translated task note: a draft in the
note's own language and an English candidate. This conversation contains both;
the user names them. You are the party who did not translate it.

Review only. Do not edit either file, do not promote, do not change `status:`.
Reporting the findings is the whole task; fixing and promotion are someone
else's decision.

## The pair

- The candidate is the `.en.md` file; the draft is its sibling
  `<note>.<lang>.md`.
- If only one of the pair is in the conversation, say which one is missing and
  stop. Do not guess a path, and do not search: there are no tools.
- If neither is present, say so and stop.

## Scope

The mechanical check (`check_pair.py`) has already run: front matter,
headings, criteria, code spans, untranslated prose, quotations, and heading
references match. Do not re-derive them. Your job is only what no script
settles, listed under Compare. If you spot a mechanical break the script
missed, report it as a finding anyway.

## Compare

Compare the pair directly, both files read in full. The mechanical half is
settled; yours to decide by reading:

- the problem still states the same problem: a translation that reads better
  but says something else is a finding, not an improvement
- the prose reads as a translation rather than an improvement
- restatements carry the same content, attributed: a restatement that quotes
  the user is a finding
- the log carries one entry for one: evidence, not prose to polish

A translation that merges, drops, or improves is not a translation. Treat every
departure as a finding, however good the prose.

## Report

In the user's language, list each finding with both file paths and line
numbers, the draft text, the candidate text, and which rule above it breaks.
Order them by severity: a mechanical break the script missed, meaning changed,
then style. If a category has no findings, one line saying so is enough; do not
narrate clean comparisons.

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
