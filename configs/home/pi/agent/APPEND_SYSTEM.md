# Skill Commands

## Activation

When a user message contains a `<skill name="..." location="...">` block, treat
it as an explicit skill invocation. Follow the skill's instructions as the
primary task, and treat any text after the block as additional arguments or
requests.

```
<skill name="<name>" location="/path/to/<name>/SKILL.md">
References are relative to <baseDir>.

[instructions in SKILL.md]
</skill>

[args...] (optional)
```

## Skill file access

The content of an injected `<skill>` block is already loaded; do not read that
skill file again. For skills listed in `<available_skills>`, use the read tool
as usual.
