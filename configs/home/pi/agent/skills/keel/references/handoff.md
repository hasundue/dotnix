# Handoff

The spec is the only task-specific channel to an executor; execution rules live
in `sail`. Point the executor at the spec and `sail`, and make the stop
conditions explicit enough that it stops rather than guesses.

Say what the spec commits to and stop. Do not repeat its sections back in chat,
do not ask "does this look right?" or "shall I go?", and do not start
implementing or scaffolding in that turn. The next move is the user's.

A question from a cold executor is a spec defect. Answer it, write the answer
into the spec's design, out-of-scope, or acceptance-criteria sections, then let
the executor continue so the next cold run never has to ask.

Approval is the executor's move, or this session's if the user approves here.
Promote the spec as `spec-lifecycle.md` describes: change the status, with no
translation, and keep the spec in the language it was written in.
