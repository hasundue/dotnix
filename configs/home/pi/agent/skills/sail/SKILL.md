---
name: sail
description: >
  Execute an agreed spec from its task note in the notes vault: work the
  acceptance criteria with evidence, and stop on blockers instead of guessing.
  Use after a spec gate such as keel, when a task note already defines the
  problem and criteria, or when the user says "execute the spec", "start the
  work", "implement the plan", or hands off an agreed note.
---

# Sail

Keel lays the spec; sail executes it. The agreement is already made. Do not
reopen the interview, rewrite the problem, or cut a branch unless the spec or
the user asks for it.

## Invariants

1. **Find and read the task note before touching code.**
2. **Every acceptance criterion ends with evidence or an explicit unmet
   report.**
3. **Merging waits for the user's word; the merge closes the note.**
4. **Scope moves in the note first, then gets re-confirmed.**
5. **A blocker is written down and raised, never silently absorbed.**
6. **A note that is not English is translated and checked before any code
   changes, and a report speaks the language of the conversation.**

Everything else -- implementation order, commits, test commands -- follows the
repo and the note.

## Find the note

Free-form wording -- "execute the spec", "start on the idle timeout thing" -- is
a lookup, not permission to begin. Resolve it to a note before touching code,
and stop when nothing matches.

1. A path the user passed wins.
2. Otherwise search the project's notes for the task's own words as the user
   gave them, in the title, the problem, and the branch:

   ```sh
   cd ~/notes/projects/<project>
   rg -il --glob '*.md' '<terms>' . | while read -r f; do
     rg -q '^status: done' "$f" || echo "$f"
   done
   ```

   Only the open notes are candidates. A title or problem match is strong
   evidence; a branch match alone is not -- see step 3. A `<note>.ja.md` /
   `<note>.en.md` pair is one note mid-translation, not two.

3. Otherwise look for a note whose `branch:` matches the current branch and
   whose `status` is not `done`. Branch is the weakest signal of the three: keel
   does not cut branches, it records the one it ran on, so `main` is the common
   value, several open notes may claim it, and the note may be recorded on
   `main` while the work happens on a branch cut later. When the match is
   ambiguous, treat it as no match.
4. Otherwise list that project's notes with `status != done`, newest first
   (`ls -t`), and ask which one -- the filenames are usually enough.
5. Otherwise say that nothing matches and ask. Never guess, and never start the
   work without a note.

When several open notes fit about equally, name them and ask which. When the
note was found rather than handed over, say which one you are taking -- path and
title -- before starting; that is a report, not a request for approval.

The project name comes from git, so worktrees resolve correctly:

```sh
basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
# ~/dotnix.pi-workflow -> dotnix
```

Read the note fully. If it is missing, empty, or has no acceptance criteria,
stop and ask. A note still marked `draft` is normal: the instruction that
brought you here is the go, so do not ask whether it is agreed -- agree it,
then implement. If `status: blocked`, read `## Blocker` first. If
`status: done`, there is nothing to execute.

Agreeing a note that is not English is the one thing that happens before any
code changes. The rule is the vault's -- `../vault/references/conventions.md`:
translate into `<note>.en.md`, have someone who did not translate it check the
pair, then promote -- `status: agreed`, `translated:` set, `<note>.en.md` to
`<note>.md`, draft deleted.

If the check needs a party that is not in this session, stop after the
translation and say so -- no code changes while the pair is unsettled. A check
that fails leaves the draft `draft` and discards the candidate. A draft already
in English needs only the promotion.

Then check the current branch and working tree so you know what you are
changing. Do not push, rewrite history, or discard unrelated work unless the
note or the user asks for it.

## Branches

Create or switch branches only when the user asks. If the work is on
`main`/`master` and the user has said nothing, ask instead of branching
silently. Keep `branch:` in the note in step with the branch actually used.

## Execute

Work through the acceptance criteria, not through a feeling of doneness. Use
each criterion's `verify:` to decide what to run or inspect.

- Tick each criterion as you verify it, recording what proves it: the command
  and its result, or what you observed and where.
- Leave missed criteria unticked and add `unmet: <reason>`. Never tick one to
  look busy, and never reword one to make it pass.
- If a criterion is already satisfied, record the evidence instead of changing
  code.
- Follow the repository's own rules for tests, formatting, and commits.
- The note is English from approval on: log entries, blockers, and scope
  changes are written in it. What the user says is restated, never quoted.
- If the note is silent on a local implementation detail, use judgment and note
  it under `## Log`; silence is not permission to change the agreed outcome.

## Scope changes and blockers

When reality contradicts the note -- a constraint was wrong, a step is
impossible, a criterion is incomplete, or the work needs to grow -- update the
note before acting, then ask for re-confirmation. Do not drift silently.

Stop instead of grinding when:

- the same failure happens twice -- write the cause and stop;
- the work needs to touch something outside the spec -- stop;
- a genuine trade-off needs a human decision -- stop.

Write the situation under `## Blocker`: what was tried, what happened, the
likely cause, and the options you see. Set `status: blocked`. Then ask. A stop
without a written trace is a failed handoff.

## Verify and report

Walk the acceptance criteria one by one and report what proves each: the command
and its result, or what you observed and where. Unmet criteria are reported as
unmet, not renegotiated after the fact.

Do not call the work done because the diff looks plausible. The criteria decide.
Report what passed and what is unmet, then leave the note open: the merge closes
it (`status: done`). If the task ends without a merge, the user's word closes
it. Do not ask whether to close, and do not close it before the merge or that
word.

End with a report in the language of the conversation: what changed, which
criteria passed with what evidence, what is unmet, and what still needs a
decision. When the session gives no signal -- `/sail <path>` and no prose
since -- take the note's `session_lang:`. If the user's language later
disagrees with the field, update the field rather than answering in a language
nobody asked for; from approval on the body stays English either way. The next
action is the user's.

When the next action is the user's judgment -- a listen, a look, a preference --
ask for the judgment itself, not for a format. Never dictate the shape of the
user's reply ("in one line", "as a table"); the note's criteria bind what is
decided, not how the user speaks. Record the decision under `## Log` in the
note's language: what was decided and why, restated rather than quoted.

## Merge

Merging waits for the user as well. Do not ask whether to merge: when the work
is done, say where the branch stands and leave it there. Merge when the user
says to, and only then.

Before merging:

- Run the repository's final gates on the branch, typically the formatter check
  and the full test suite.
- Follow the repository's merge convention. Where it has none, keep history
  linear -- no merge commit -- and say which shape you used.

The note is outside the repository, so a squash merge needs no cleanup: no files
to strip, no archive branch, no guard hook. After the merge, close the note --
`status: done` -- and record what it should point at:

```yaml
pr: 123
merge_commit: abc1234
```

Log the merge and the close.

Never rewrite `main` or force-push it.
