---
name: sail
description: >
  Execute an agreed spec from SPEC.md in the working branch: work the
  acceptance conditions with evidence, and stop on blockers instead of
  guessing. Use after a spec gate such as keel, when a task has an agreed spec,
  or when the user says "execute the spec", "start the work", "implement the
  plan", or hands off an agreed spec.
---

# Sail

Keel lays the spec; sail executes it. The agreement is already made. Do not
reopen the interview, rewrite the problem, or cut a branch unless the spec or
the user asks for it.

## Invariants

1. **Find and read the spec before touching code.**
2. **Every acceptance condition ends with evidence or an explicit unmet
   report.**
3. **Merging waits for the user's word; the merge leaves the spec out of `main`.**
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
   search the vault. Treat a `.ja.md` / `.en.md` pair as one spec mid-translation.
3. Otherwise say that nothing matches and ask. Never guess, and never start the
   work without a spec.

When several open specs fit about equally, name them and ask which. When the
spec was found rather than handed over, say which one you are taking -- path and
title -- before starting; that is a report, not a request for approval.

Read the spec fully. If it is missing, empty, or has no acceptance criteria,
stop and ask. A spec still marked `draft` is normal: the instruction that
brought you here is the go, so do not ask whether it is agreed -- approve it,
then implement. If `status: blocked`, read `## Blocker` first. If `status: stale`,
stop and ask: the work was dropped.

Agreeing a spec that is not English is the one thing that happens before any
code changes. Follow `../keel/references/spec-lifecycle.md`: translate, check
through skiff, promote. You translated it, so you are not the checker. Use a
checker model different from your own when the user or the project names one,
and ask if unsure. Read the child's conclusion. If it reports no substantive
issues and concludes that the agreement was preserved, promote. Otherwise leave
the status `draft`, fix the candidate, and re-check the full pair once with the
same checker. If findings remain, or the conclusion is missing or unclear, stop
and ask the user.

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
  `unmet: <reason>`. Never tick one to look busy, and never reword a condition
  to make it pass.
- If a condition is already satisfied, record the evidence instead of changing
  code.
- Follow the repository's own rules for tests, formatting, and commits. Commit
  the promoted `SPEC.md` with the work; drafts and candidates are never
  committed.
- Scope changes go into the spec before acting (see below). The spec is English
  from approval on, and what the user says is restated, never quoted.
- If the spec is silent on a local implementation detail, use judgment and keep
  the detail in conversation or the commit message. Silence is not permission to
  change the agreed outcome.

## Scope changes and blockers

When reality contradicts the spec -- a constraint was wrong, a step is
impossible, a criterion is incomplete, or the work needs to grow -- update the
design, out-of-scope, or acceptance-criteria section before acting, then ask for
re-confirmation. Put the context for the change in that commit's body: why the
spec moved, and what was considered -- for example, what was tried, what
happened, the likely cause, and the options. Do not drift silently.

Stop instead of grinding when:

- the same failure happens twice -- write the cause and stop;
- the work needs to touch something outside the spec -- stop;
- a genuine trade-off needs a human decision -- stop.

When a stop needs a handoff, set `status: blocked` and write the context under
`## Blocker` -- the section never appears without that status. Write what is
needed to resume; for example, what was tried, what happened, the likely cause,
and the options. A commit that only adds the status and the section needs no
body: the spec holds the context. A scope change in the same commit still
carries its own context in the body. Then ask. A blocker without a written
trace is a failed handoff.

Only on the user's word does a block clear: set `status: agreed` and move the
context from `## Blocker` into that commit's body before removing the section --
the spec no longer carries it. If the user drops the work -- blocked or not --
set `status: stale`. If a `## Blocker` section exists, move its context into that
commit's body and remove the section; otherwise put why the work was dropped in
that commit's body. A stale spec is not resumed without the user's word; on
resumption, re-confirm the spec, set `status: agreed`, and carry the context
from the stale commit's body into the work.

## Verify and report

Walk the acceptance conditions one by one and report what proves each: the
command and its result, or what you observed and where. Unmet conditions are
reported as unmet, not renegotiated after the fact.

Do not call the work done because the diff looks plausible. The conditions
decide. Report what passed and what is unmet, then leave the spec in place: the
merge reorganization leaves it out of `main`. If the task ends without a merge, the user's word closes it.
Do not ask whether to close, and do not reorganize the branch before the merge or that
word.

End with a report in the language of the conversation: what changed, which
conditions passed with what evidence, what is unmet, and what still needs a
decision. When the session gives no signal -- `/sail <path>` and no prose since --
take the spec's `session_lang:`. If the user's language later disagrees with the
field, update the field rather than answering in a language nobody asked for;
from approval on the body stays English either way. The next action is the
user's.

When the next action is the user's judgment -- a listen, a look, a preference --
ask for the judgment itself, not for a format. Never dictate the shape of the
user's reply ("in one line", "as a table"); the spec's conditions bind what is
decided, not how the user speaks. Record the decision in conversation and the
commit message; the spec has no Log section.

## Merge

Merging waits for the user as well. Do not ask whether to merge: when the work
is done, say where the branch stands and leave it there. Merge when the user
says to, and only then.

A spec marked `stale` has no outcome for `main`; do not merge that branch. If
the user asks for it anyway, stop and ask where the context belongs.

Before merging:

- Run the repository's final gates on the branch, typically the formatter check
  and the full test suite.
- Reorganize the branch into outcome commits by the repository's merge procedure,
  which `AGENTS.md` points to. The user approves the reorganized form before the
  merge. The commits that reach the target carry the spec's `## Problem` in their
  body. They also carry the context recorded in spec-change commit bodies -- why
  the spec moved, or the context moved out of a cleared blocker -- in the outcome
  commit that keeps the change; a checkpoint body alone does not survive
  reorganization. When no outcome commit keeps that change, stop and ask where
  the context belongs. If the procedure cannot carry either, stop and ask. If
  the repository has no merge procedure, stop and ask.
- The target must receive no `SPEC*` file. Check that `git ls-tree --name-only
  HEAD -- SPEC.md SPEC.ja.md SPEC.en.md` prints nothing. Check that the target has
  no spec of its own with `git ls-tree --name-only <target> -- SPEC.md SPEC.ja.md
  SPEC.en.md`; if it prints anything, stop and ask, because that file is not this
  task's. Delete any untracked `SPEC*` file left in the worktree, and read `git
  status --short`: it must be clean.
- Follow the repository's merge convention. Where it has none, keep history
  linear -- no merge commit -- and say which shape you used.

The reorganized commits are what `main` receives: outcome commits that carry the
problem, and no spec file. Record the outcome in conversation and commit messages.

Never rewrite `main` or force-push it.
