# Spec language lifecycle

The agreement is a `SPEC.md` in the working tree, not a note in the vault. A
Japanese draft is `SPEC.ja.md`; an English draft is `SPEC.md`. Ask before
inventing another language suffix. Approval turns the draft into the English
spec once, and only the promoted file is committed.

## Heading map

A Japanese draft uses Japanese headings. On translation, map them as follows
and update every reference to them in the body:

| Japanese draft    | English spec             |
| ----------------- | ------------------------ |
| `## 現在の動作`   | `## Current behavior`    |
| `## 設計`         | `## Design`              |
| `## 対象外`       | `## Out of scope`        |
| `## 受け入れ条件` | `## Acceptance criteria` |
| `## 停止条件`     | `## Stop conditions`     |
| `## ブロッカー`   | `## Blocker`             |

Frontmatter keys, paths, commands, code identifiers, and links stay as they
are. Writing a Japanese draft needs only `templates.ja.md`; the map is here
so the writer does not have to read English to write it.

## 1. Translate

For a Japanese session, translate `SPEC.ja.md` into `SPEC.en.md` next to it in
the worktree. Preserve the agreement's meaning: its design decisions and their
reasons, scope, acceptance conditions and their verification methods, and
task-specific stop conditions. Translate prose, including a manual verification
step written as a sentence. Keep commands, paths, code identifiers, and links
usable; update a heading reference if its heading is translated. Backticks
alone do not make text immutable. The candidate may clarify or reorganize the
spec, but must not add, remove, or change an agreed commitment.

Read the pair against each other once before handing it over, as a meaning
check. Do not write or run a script to compare them. The independent check in
the next step decides whether the agreement survived the translation.

## 2. Independent check

Have another agent check the pair. It did not translate the text. Give it the
paths of `SPEC.ja.md` and `SPEC.en.md` in the worktree, say which is which,
and use `~/.pi/agent/skills/vault/prompts/review-translation.md` as its task
prompt. The `skiff` skill describes how to launch the check and continue the
same checker. The model, and optionally the thinking level, come from user
instructions or project conventions; ask if unsure.

If the check finds a substantive problem, fix the candidate in place and
re-check the pair in full with the same checker: it holds the old copy of the
candidate otherwise. If the re-check still finds a problem, ask the user rather
than grinding through more rounds. Anything that fails is fixed before
promotion, not after. Nothing is committed while the check is open.

## 3. Promote

Promote with `status: agreed`. Set `translated: <YYYY-MM-DD>` when the spec
was translated; leave it empty when it was written in English from the start.

For a translated pair, rename `SPEC.en.md` to `SPEC.md` in the worktree and
delete `SPEC.ja.md`. Keep `SPEC.context.md` when it exists. Do not commit the
draft or the candidate: only the promoted `SPEC.md`, together with
`SPEC.context.md`, goes into the work commit. For a draft written in English,
those rename and delete steps do not apply; promotion is the metadata update
only.

While the check is open, `SPEC.ja.md` and `SPEC.en.md` are one spec, not two.
From approval on, the spec is English for life, including blockers and any
scope changes written into it.
