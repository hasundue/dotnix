# Verification

Read this when the implementation is done and before reporting.

Walk the acceptance conditions one by one. Report what proves each: the command
and its result, or what you observed and where. Conditions that are unmet are
reported as unmet, never renegotiated after the fact. Do not call the work done
because the diff looks plausible; the conditions decide.

- Do not label verification-method lines; the count of conditions stays
  separate from the count of checks.
- End with a report in the language of the conversation: what changed, which
  conditions passed with what evidence, what is unmet, and what still needs a
  decision. If the session gives no signal, ask which language to report in;
  the spec has no language field. The spec body keeps its language.
- When the next action is the user's judgment -- a listen, a look, a preference
  -- ask for the judgment itself, not for a format. Never dictate the shape of
  the user's reply. Record the decision in conversation and the commit message;
  the spec has no Log section.

Do not ask whether to close, and do not reorganize the branch before the merge
or the user's word closes the task. The next action is the user's.
