# Bash tooling

The bash tool runs in the session's working directory. Do not prefix a command
with cd to reach a path a tool can take directly, and use the program's own
directory flag when it has one.

```sh
rg -n "waku" ~/dotnix/configs         # yes
cd ~/dotnix && rg -n "waku" configs   # no
git -C ~/dotnix status                # yes, git's own flag
cd sub && ./build.sh                  # yes, it writes into its cwd
```

Use pi's own tools for reading, searching, and listing (read, grep, find, ls)
instead of their shell equivalents. Each takes any path, so scope is no reason
to prefer bash. Reach for rg, fd, or ls only when pi's tools cannot express the
query, such as when the result has to feed a pipeline.

```sh
rg -n "waku" ~/dotnix/configs   # no, the grep tool takes the same path
cat ~/.pi/agent/AGENTS.md       # no, read does
```

Line ranges go straight to the read tool; do not slice a file with sed, cat,
head, or tail.

```sh
sed -n 270,285p FILE            # no, read with offset 270 and limit 16
```

Make one call per inspection instead of chaining commands, and let failures
surface instead of silencing them.

```sh
grep a x && grep b y            # no, two grep calls
rg foo path 2>/dev/null         # no, the error is the point
```

If the tool you need is missing, say so and ask; do not substitute a shell scan
for it.

# Language

- The user is a native Japanese speaker who writes instructions in Japanese but
  also uses English, depending on the complexity of the task or even on their
  mood. Reply in the same language as their instruction unless they say
  otherwise.
- Prefer writing git-managed files in English, unless overridden by the project
  preference or user instructions.
