# Language

- The user is a native Japanese speaker and gives instructions in Japanese or
  English, depending on the task's complexity or even their mood. Reply in the
  language of the user's instruction unless they say otherwise.
- Insert a half-width space between CJK text and English words.
- Be direct and concise to save tokens.
- Prefer writing git-managed files in English, unless overridden by the project
  preference or user instructions.

# Answering Questions

When asked how something is specified or behaves — a flag, an option, an API,
upstream behaviour — climb these stages and stop at the first that answers:

1. Your own knowledge, for stable facts about well-known tools and standards.
2. The web: official documentation, specifications, and upstream source. Use the
   `ketch` skill.
3. An experiment in this environment: run commands, build, evaluate.

Do not open with an experiment. Say when a stage left the question open and you
are moving to the next one.

# Comments and prose

- Describe the code and the documents as they are now. Do not explain what used
  to be there, why an earlier approach was worse, or what would break without
  code or text that no longer exists.
- Keep a reason only while the code or instruction it justifies is present.
  Commit messages and git history keep the rest.
- Do not let the conversation leak into files: they must stand alone for a
  reader who was not part of the dialogue.
