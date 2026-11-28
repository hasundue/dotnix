# Spec authoring

One written spec carries the agreement in the language of the session that
wrote it. Its name and location come from project convention or the user.

## Frontmatter

Keys stay English. `status` is `draft` before approval, `agreed` after it,
`blocked` while the work waits on a decision, and `stale` when it will not land.
A stale spec has nothing for `main`. A dropped draft is deleted uncommitted.

## Templates

Templates live in `templates/`, one per session language, and contain only the
frontmatter and the sections. Copy the matching one to the agreed location and
fill it in; the template file name is not the spec name.

## Body

Write the body in the session language. The language stays for the life of the
spec: scope changes and blockers are written in it too.

Write the problem in two to four lines with no solution in it: the reason for
the change, plain enough for an executor to judge a trade-off. Keep history out
unless it changes a decision. Write one design line per decision that constrains
implementation, with its reason, and give a path its own line when a decision
depends on it. State what is explicitly out of scope; silent disagreement about
that is half of misalignment.

Stop conditions are task-specific and end the work early; omit the section when
there are none.

Name the paths, the current behaviour, the decisions with their reasons, and the
commands that check them.

## Criteria

- A condition is an observable outcome, not a task. Split it until you can say
  how to check it, or drop it.
- A condition that ends in the user's judgment states what to decide, never how
  to answer; the spec records the answer in whatever shape the user gives it.
- Write each condition as a plain `-` item and hang its verification methods
  beneath it as two-space-indented `- [ ]` lines, and the observed value or
  unmet reason four spaces beneath those.
- The out-of-scope section uses plain `-` items, so `[ ]` keeps a single
  meaning.
- A criterion the change makes obsolete is replaced; the criteria describe the
  spec as it stands.

## Approval

Approval is a status change from `draft` to `agreed`. There is no independent
check. A scope change after approval edits the body and returns `status` to
`draft` until it is approved again.
