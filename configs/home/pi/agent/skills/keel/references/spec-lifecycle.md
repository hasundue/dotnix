# Spec lifecycle

The agreement is a `SPEC.md` in the linked worktree. A Japanese session drafts
`SPEC.ja.md`; an English session drafts `SPEC.md`. Ask before inventing another
language suffix.

Only the promoted `SPEC.md` is committed, with the work. Drafts and candidates
stay uncommitted. Sail removes the spec before the merge.

## Heading map

A Japanese draft uses Japanese headings. On translation, map them as follows and
update every reference to them in the body:

| Japanese draft    | English spec             |
| ----------------- | ------------------------ |
| `## 問題`         | `## Problem`             |
| `## 設計`         | `## Design`              |
| `## 対象外`       | `## Out of scope`        |
| `## 受け入れ条件` | `## Acceptance criteria` |
| `## 停止条件`     | `## Stop conditions`     |
| `## ブロッカー`   | `## Blocker`             |

Frontmatter keys, paths, commands, code identifiers, and links stay as they are.
Writing a Japanese draft needs only `templates.ja.md`; the map is here so the
writer does not have to read English to write it.

## 1. Translate

For a Japanese session, translate `SPEC.ja.md` into `SPEC.en.md` next to it in
the worktree. Preserve the agreement's meaning: the problem, the design
decisions and their reasons, scope, acceptance conditions and their verification
methods, and task-specific stop conditions. Translate prose, including a manual
verification step written as a sentence. Keep commands, paths, code identifiers,
and links usable; update a heading reference if its heading is translated.
Backticks alone do not make text immutable. The candidate may clarify or
reorganize the spec, but must not add, remove, or change an agreed commitment.

Read the pair against each other once before handing it over, as a meaning
check. Do not write or run a script to compare them. The independent check in
the next step decides whether the agreement survived the translation.

## 2. Independent check

Have another agent check the pair. It did not translate the text. Run the skiff
launcher from the worktree, with the skiff translation-check prompt, and name the
session so a follow-up can resume it:

```sh
~/.pi/agent/skills/skiff/scripts/run.py --session-id spec-check-<slug> \
  --system-prompt ~/.pi/agent/skills/skiff/references/prompts/translation-check.md \
  @SPEC.ja.md @SPEC.en.md \
  "SPEC.ja.md is the original Japanese draft; SPEC.en.md is its English translation candidate. Both are attached. Treat each acceptance condition, each verification method, each out-of-scope item, and each stop condition as a commitment: a weakened, dropped, or added one is a finding."
```

The model, and optionally the thinking level, come from user instructions or
project conventions (`--model`, `--thinking`); ask if unsure.

If the check finds a substantive problem, fix the candidate in place and
re-check the full pair with the same checker: resume `spec-check-<slug>` with
`--session-id` and no `--system-prompt`, and attach the changed `SPEC.en.md`
again. The checker otherwise holds the old copy. If the re-check still finds a
problem, ask the user rather than grinding through more rounds. Anything that
fails is fixed before promotion, not after. Nothing is committed while the check
is open.

## 3. Promote

Promote with `status: agreed`.

For a translated pair, rename `SPEC.en.md` to `SPEC.md` in the worktree and
delete `SPEC.ja.md`. For a draft written in English, promotion is the metadata
update only.

While the check is open, `SPEC.ja.md` and `SPEC.en.md` are one spec, not two.
From approval on, the spec is English for life, including blockers and any scope
changes written into it.
