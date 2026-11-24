---
name: sail
description: >
  Execute an agreed spec from SPEC.md in the working branch: work the
  acceptance conditions with evidence, and stop on blockers instead of
  guessing. Use after a spec gate such as keel, when a task has an agreed spec,
  or when the user says "execute the spec", "start the work", "implement the
  plan", or hands off an agreed note.
---

# Sail

Keel lays the spec; sail executes it. The agreement is already made. Do not
reopen the interview, rewrite the problem, or cut a branch unless the spec or
the user asks for it.

## Invariants

1. **Find and read the spec before touching code.**
2. **Every acceptance condition ends with evidence or an explicit unmet
   report.**
3. **Merging waits for the user's word; the spec is deleted before the merge.**
4. **Scope moves in the spec first, then gets re-confirmed.**
5. **A blocker is written down and raised, never silently absorbed.**
6. **A spec that is not English is translated and checked before any code
   changes, and a report speaks the language of the conversation.**

Everything else -- implementation order, commits, test commands -- follows the
repo and the spec.

## Find the spec

Free-form wording -- "execute the spec", "start on the idle timeout thing" -- is
a lookup, not permission to begin. Resolve it to a spec before touching code,
and stop when nothing matches.

1. A path the user passed wins. An explicit path to an old vault task note is
   read as-is; do not migrate it.
2. Otherwise automatic discovery looks only at the repository: `SPEC.md`,
   `SPEC.ja.md`, and `SPEC.en.md` at the root of the current worktree. Do not
   search the vault. Treat a `.ja.md` / `.en.md` pair as one spec
   mid-translation.
3. Otherwise say that nothing matches and ask. Never guess, and never start the
   work without a spec.

When several open specs fit about equally, name them and ask which. When the
spec was found rather than handed over, say which one you are taking -- path and
title -- before starting; that is a report, not a request for approval.

Read the spec fully. If it is missing, empty, or has no acceptance criteria,
stop and ask. A spec still marked `draft` is normal: the instruction that
brought you here is the go, so do not ask whether it is agreed -- approve it,
then implement. If `status: blocked`, read `## Blocker` first.

Agreeing a spec that is not English is the one thing that happens before any
code changes. Follow `../keel/references/task-note-lifecycle.md`: translate,
check, promote.

You are the translator, so you must not be the checker -- delegate the check
to a skiff. The model, and optionally the thinking level, should be
specified by user instructions or project conventions -- prefer one different
from the translator's. Ask if unsure. Read the child's conclusion. If the
checker reports no substantive issues and concludes that the agreement was
preserved, promote per the lifecycle; the candidate becomes the spec. Otherwise
leave the draft `draft`, fix the candidate, and re-check the full pair once. If
findings remain, or the conclusion is missing or unclear, stop and ask the user.

- child non-zero exit -> stop and report the exit code and stderr; no code
  changes while the pair is unsettled.

A draft already in English needs only the promotion.

Then check the current branch and working tree so you know what you are
changing. Do not push, rewrite history, or discard unrelated work unless the
spec or the user asks for it.

## Branches

Create or switch branches only when the user asks. If the work is on
`main`/`master` and the user has said nothing, ask instead of branching
silently. The spec belongs to the worktree it was written in; there is no branch
field to keep in sync.

## Execute

Work through the acceptance conditions, not through a feeling of doneness. Use
each condition's `- [ ]` verification methods to decide what to run or inspect.

- Tick a verification method when you carry it out, recording what proves it:
  the command and its result, or what you observed and where.
- Leave a method unticked when its condition is unmet and add
  `unmet: <reason>` to it. Never tick one to look busy, and never reword a
  condition to make it pass.
- If a condition is already satisfied, record the evidence instead of changing
  code.
- Follow the repository's own rules for tests, formatting, and commits.
- The spec is English from approval on: scope changes go into its design,
  out-of-scope, and acceptance-criteria sections, and blockers are written in
  English. What the user says is restated, never quoted.
- If the spec is silent on a local implementation detail, use judgment and keep
  the detail in conversation or the commit message; the spec has no log
  section. Silence is not permission to change the agreed outcome.

## Scope changes and blockers

When reality contradicts the spec -- a constraint was wrong, a step is
impossible, a criterion is incomplete, or the work needs to grow -- update the
design, out-of-scope, or acceptance-criteria section before acting, then ask for
re-confirmation. Do not drift silently.

Stop instead of grinding when:

- the same failure happens twice -- write the cause and stop;
- the work needs to touch something outside the spec -- stop;
- a genuine trade-off needs a human decision -- stop.

Write the situation under a `## Blocker` section on demand: what was tried,
what happened, the likely cause, and the options you see. Set
`status: blocked`. Then ask. A stop without a written trace is a failed
handoff.

## Verify and report

Walk the acceptance conditions one by one and report what proves each: the
command and its result, or what you observed and where. Unmet conditions are
reported as unmet, not renegotiated after the fact.

Do not call the work done because the diff looks plausible. The conditions
decide. Report what passed and what is unmet, then leave the spec in place: the
merge removes it. If the task ends without a merge, the user's word closes it.
Do not ask whether to close, and do not delete the spec before the merge or
that word.

End with a report in the language of the conversation: what changed, which
conditions passed with what evidence, what is unmet, and what still needs a
decision. When the session gives no signal -- `/sail <path>` and no prose
since -- take the spec's `session_lang:`. If the user's language later
disagrees with the field, update the field rather than answering in a language
nobody asked for; from approval on the body stays English either way. The next
action is the user's.

When the next action is the user's judgment -- a listen, a look, a preference --
ask for the judgment itself, not for a format. Never dictate the shape of the
user's reply ("in one line", "as a table"); the spec's conditions bind what is
decided, not how the user speaks. Record the decision in conversation and the
commit message; the spec has no Log section.

## Merge

Merging waits for the user as well. Do not ask whether to merge: when the work
is done, say where the branch stands and leave it there. Merge when the user
says to, and only then.

Before merging:

- Run the repository's final gates on the branch, typically the formatter check
  and the full test suite.
- Follow the repository's merge convention. Where it has none, keep history
  linear -- no merge commit -- and say which shape you used.
- Delete `SPEC.md` and `SPEC.context.md` when present from the worktree. Run
  `git status --short` and read the result. Stop and report if a `SPEC.*`
  file remains; do not merge with the spec still in the tree.

The spec and its context file were committed with the work and are removed
before the merge: nothing to strip after it, no archive branch, and no guard
hook. Record the outcome in conversation and commit messages.

Never rewrite `main` or force-push it.
