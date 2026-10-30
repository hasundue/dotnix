# Search and exploration

- Prefer `rg` over `grep -r`, and `fd` over `find`.
- For a single simple search, pi's `grep` / `find` tools are also fine; use them
  when they avoid shell quoting or output-size problems.
- Use bash when you need pipelines, multiple commands, or shell features.
- Keep searches inside the project. Do not run `find /`, `grep -r ... /`, or
  equivalent filesystem-wide scans unless explicitly asked.
- Skip `node_modules`, `.git`, and build output.

# Language

- Write files in English: source, comments, tests, commit messages,
  configuration, documentation, skills, and prompt templates.
- Do not write Japanese in files, unless the file's content is itself Japanese
  text being processed (translations, fixtures, sample data) or a format
  requires it.
- Other non-ASCII characters (typography, arrows, math symbols) are fine.
