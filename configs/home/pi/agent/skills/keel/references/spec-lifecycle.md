# Spec lifecycle

The agreement is one `SPEC.md` at the root of a linked worktree, in the language
of the session that wrote it. There is no language suffix and no translation.
Ask before inventing another file name.

Only the promoted spec is committed, with the work. Drafts stay uncommitted.
Sail leaves the spec out of the commits that land on `main`.

## Worktree

One `SPEC.md` sits at the root of a linked worktree: a worktree maps one-to-one
to a branch. In the primary checkout, stop and ask the user to switch to one.
Keel does not create worktrees or branches.

Before writing, check for any existing `SPEC*` file, tracked or not. Read it
and ask before drafting another; never overwrite or rename one on your own.

```sh
git rev-parse --path-format=absolute --git-dir --git-common-dir
git ls-files 'SPEC*'; ls SPEC* 2>/dev/null
```

The two `rev-parse` paths differ only in a linked worktree.

## Frontmatter

Keys stay English. `status` is one of `draft`, `agreed`, `blocked`, `stale`.
`stale` means a promoted spec's work is no longer being pursued; a dropped draft
is deleted uncommitted and never becomes `stale`. There is no language field.

## Sections

Templates live in `templates/`, one per session language, and contain only the
frontmatter and the sections. Copy the matching one into the worktree as
`SPEC.md` and fill it in; the template file name is not the spec name. Only
Japanese and English templates exist, so ask before adding another language.
Headings stay in the spec's language; a reader finds a section by its position
and content, not by an English heading name.

## Writing the body

Write the problem in two to four lines with no solution in it: the reason for
the change, plain enough for an executor to judge a trade-off. Keep history out
unless it changes a decision. Write one design line per decision that constrains
implementation, with its reason, and give a path its own line when a decision
depends on it. State what is explicitly out of scope; silent disagreement about
that is half of misalignment.

Write every section so it can be read cold -- by a session with none of the
conversation. No "as discussed" or "the usual place". Name paths, current
behaviour, decisions and their reasons, and commands.

When sail reorganizes the branch for the merge, the problem becomes the body of
the commit that lands the outcome, so the reason outlives the spec.

## Line width

Wrap prose at 80 half-width columns, counting a full-width character as two.
Keep commands, paths, code identifiers, and links usable; break them only where
the syntax keeps them copyable. The formatter does not wrap Markdown prose, so
the writer wraps it.

## Checking work

- A condition is an observable outcome, not a task. Split it until you can say
  how to check it, or drop it.
- A condition that ends in the user's judgment states what to decide, never how
  to answer; the method records the answer in whatever shape the user gives it.
- Write each condition as a plain `-` item and hang its verification methods
  beneath it as two-space-indented `- [ ]` lines.
- `- [ ]` is a verification method under a condition, not the condition.
- A method is recorded as `- [x] <method> -- <command and result>`. A failed or
  unrun one stays unticked, with `unmet: <reason>`.
- The out-of-scope section uses plain `-` items, so `[ ]` keeps a single
  meaning.
- Ticking is not renegotiation. Changing the text of a condition needs a fresh
  confirmation.
- Do not label method lines; that keeps the count of conditions separate from
  the count of checks.
- Do not add Decisions or Log sections; git and conversation carry that history.
- The stop-conditions section holds task-specific limits only; the common ones
  live in sail.

## When blocked

The blocker section appears only with `status: blocked`. Place it after the
stop-conditions section, or last if that section is omitted. Give it a heading
in the spec's language that names the block, and write the context needed to
resume -- for example, what was tried, what happened, the likely cause, and the
options. When the status leaves `blocked`, move that context into the commit
body and remove the section.

## Approval

Approval is a status change from `draft` to `agreed`. There is no translation
and no independent check. Write the body in the session language and restate
what the user wants rather than quoting them. Scope changes and blockers follow
the same language, and the body keeps its language for life.
