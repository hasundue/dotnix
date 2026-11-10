# Bash tooling

- Use pi's tools rather than the shell equivalents: `read` for files, `grep` for
  content search, `find` for filename search, `ls` for listings. Each takes any
  `path`, so scope is no reason to prefer `bash`. Reach for `rg`, `fd`, or `ls`
  only when pi's tools cannot express the query, such as when the result must
  feed a pipeline or you need a filter `find` lacks.
- `read` takes line ranges directly: `sed -n 270,285p FILE` becomes `read` with
  `offset: 270, limit: 16`. Do not use `sed`, `cat`, `head`, or `tail` for this.
- Make one tool call per inspection rather than chaining with `echo`, `;`, or
  `&&`, and let failures surface instead of silencing them with `2>/dev/null`.
- If the tool you need is missing, say so and ask; do not substitute a shell
  scan for it.
- Do not `cd` on every `bash` tool call. Track your current directory from
  context, and use `pwd` or `cd` only when necessary.

# Language

- The user is a native Japanese speaker who writes instructions in Japanese but
  also uses English, depending on the complexity of the task or even on their
  mood. Reply in the same language as their instruction unless they say
  otherwise.
- Prefer writing git-managed files in English, unless overridden by the project
  preference or user instructions.
