# Spec authoring

One written spec carries the agreement in the language of the session that
wrote it. Its name and location come from project convention or the user.

## Frontmatter

Keys stay English. `status` starts at `draft` and becomes `agreed` on approval.
A dropped draft is deleted uncommitted. There is no language field.

## Sections

Templates live in `templates/`, one per session language, and contain only the
frontmatter and the sections. Copy the matching one to the agreed location and
fill it in; the template file name is not the spec name.

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

## Line width

Wrap prose at 80 half-width columns, counting a full-width character as two.
Keep commands, paths, code identifiers, and links usable; break them only where
the syntax keeps them copyable. The formatter does not wrap Markdown prose, so
the writer wraps it.

## Criteria

- A condition is an observable outcome, not a task. Split it until you can say
  how to check it, or drop it.
- A condition that ends in the user's judgment states what to decide, never how
  to answer; the method records the answer in whatever shape the user gives it.
- Write each condition as a plain `-` item and hang its verification methods
  beneath it as two-space-indented `- [ ]` lines.
- The out-of-scope section uses plain `-` items, so `[ ]` keeps a single
  meaning.

## Approval

Approval is a status change from `draft` to `agreed`. There is no independent
check. Write the body in the session language and restate what the user wants
rather than quoting them. Scope changes and blockers follow the same language,
and the body keeps its language for life.
