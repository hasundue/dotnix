# Bash tooling

The bash tool runs in the session's working directory. Do not prefix a command
with cd to reach a path a tool can take directly, and use the program's own
directory flag when it has one.

```sh
git -C ~/src/app status         # yes, git's own directory flag
make -C ~/src/app/build         # yes, make's own directory flag
cd ~/src/app && git status      # no, `-C` takes that path for you
cd sub && ./build.sh            # yes, the script writes into its cwd
```

Use pi's own tools for reading, searching, and listing (read, grep, find, ls)
instead of their shell equivalents. Each takes any path, so scope is no reason
to prefer bash. Reach for rg, fd, or ls in bash only when a dedicated tool
cannot express the query, such as when the output has to feed a pipeline.

```sh
rg -n "TODO" src                # no, the `grep` tool takes the same path
cat NOTES.md                    # no, the `read` tool does
find . -name "*.py"             # no, the `find` tool does
ls src                          # no, the `ls` tool does
fd -e py | xargs wc -l          # yes, the total has to be computed
```

Never pass a script to bash through a heredoc or a long -c string. Write the
file first, then run it.

```sh
python3 - <<'PY'                # no, the whole script fills the transcript
cat > /tmp/m.py <<'EOF'         # no, same
python3 /tmp/m.py               # yes, write the file with the `write` tool first
python3 -c 'print(1)'           # yes, when one line is enough
```

Line ranges go straight to the read tool; do not slice a file with sed, cat,
head, or tail.

```sh
sed -n 270,285p FILE            # no, `read` with offset 270 and limit 16
```

Make one call per inspection instead of chaining commands, and let failures
surface instead of silencing them.

```sh
grep a x && grep b y            # no, two `grep` calls
git log 2>/dev/null             # no, the error is the point
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
