# Language

- The user is a native Japanese speaker and gives instructions in Japanese or
  English, depending on the task's complexity or even their mood. Reply in the
  language of the user's instruction unless they say otherwise.
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
