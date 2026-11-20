# Task note language lifecycle

A task note is an agreement, not a specification to obey byte for byte. A draft
is argued in the session's language and carries `session_lang:` so a cold
session knows which tongue to report in. Approval turns it into the English
record, once, in place.

## 1. Translate

Translate into `<note>.en.md`, next to the draft. Preserve the agreement's
meaning: its problem, scope, decisions, expected outcomes, acceptance criteria,
and anything in the log that matters to those. Translate prose, including a
`verify:` step written as a sentence. Keep commands, paths, code identifiers,
and links usable; update a heading reference if its heading is translated.
Backticks alone do not make text immutable. The candidate may clarify or
reorganize the note, but must not add, remove, or change an agreed commitment.

Read the pair against each other once before handing it over, as a meaning
check. Do not write or run a script to compare them. The independent check in
the next step decides whether the agreement survived the translation.

## 2. Independent check

Have another agent check the pair. It did not translate the text and has no
tools, so hand it both files, say which is which, and use
`~/.pi/agent/skills/vault/prompts/review-translation.md` as its task prompt.
The `skiff` skill describes how to launch the check and continue the same
checker. The model, and optionally the thinking level, come from user
instructions or project conventions; ask if unsure.

If the check finds a substantive problem, fix the candidate in place and
re-check the pair in full with the same checker: it holds the old copy of the
candidate otherwise. If the re-check still finds a problem, ask the user rather
than grinding through more rounds. Anything that fails is fixed before the
promotion, not after.

## 3. Promote

Promote with `status: agreed`, `translated: <YYYY-MM-DD>`, rename
`<note>.en.md` to `<note>.md`, and delete the draft. The original does not
survive: a note that exists twice is a note whose wording drifts.

While the check is open, `<note>.ja.md` and `<note>.en.md` are one note, not
two. Discovery finds both; treat the pair as one hit. A draft already in
English needs only this step. From approval on, the note is English for life,
log entries and blockers included.
