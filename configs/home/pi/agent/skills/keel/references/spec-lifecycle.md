# Spec lifecycle

The agreement is one `SPEC.md` at the root of a linked worktree, in the language
of the session that wrote it. There is no language suffix and no translation.
Ask before inventing another file name.

Only the promoted spec is committed, with the work. Drafts stay uncommitted.
Sail leaves the spec out of the commits that land on `main`.

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

## Checking work

- Write each condition as a plain `-` item and hang its verification methods
  beneath it as two-space-indented `- [ ]` lines.
- `- [ ]` is a verification method under a condition, not the condition.
- A method is recorded as `- [x] <method> -- <command and result>`. A failed or
  unrun one stays unticked, with `unmet: <reason>`.
- The out-of-scope section uses plain `-` items, so `[ ]` keeps a single meaning.
- Ticking is not renegotiation. Changing the text of a condition needs a fresh
  confirmation.
- Do not label method lines; that keeps the count of conditions separate from
  the count of checks.
- Do not add Decisions or Log sections; git and conversation carry that history.
- The stop-conditions section holds task-specific limits only; the common ones
  live in sail.

## When blocked

The blocker section appears only with `status: blocked`. Place it after the
stop-conditions section, or last if that section is omitted. Give it a heading in
the spec's language that names the block, and write the context needed to resume
-- for example, what was tried, what happened, the likely cause, and the options.
When the status leaves `blocked`, move that context into the commit body and
remove the section.

## Approval

Approval is a status change from `draft` to `agreed`. There is no translation and
no independent check. Write the body in the session language and restate what
the user wants rather than quoting them. Scope changes and blockers follow the
same language, and the body keeps its language for life.
