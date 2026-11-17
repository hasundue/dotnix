# Bash tooling

Keep commands clean and easy for the user to follow; every rule here
serves that.

Do not prefix a command with a `cd` that only restates where it runs. The bash
tool starts every call in the session's working directory and most commands
take a directory as an argument, so track it from context and use `pwd` when
unsure. A `cd` earns its place when the commands depend on it: one program
reads better with its own flag, a run of commands in one directory under one
`cd`.

```sh
cd ~/src/app && git status              # no; `git -C ~/src/app status`
cd ~/src/app && git status && git diff  # yes; two commands, one directory
cd ~/src/app/build && make              # no; use `make -C ~/src/app/build`
cd sub && ./build.sh                    # yes; the script must run from here
```

Reach for Pi's `read`, `grep`, `find`, and `ls` before their shell
equivalents. What they return is labelled — numbered lines, path and line per
match — so a result can be cited without tracing it back to what produced it,
where shell output is only what the command chose to print. `offset` and
`limit` extend that to slices; `sed` prints bare lines you have to count. The
one thing the tools cannot do is pipe, so a result that has to feed another
command belongs to the shell.

```sh
cat NOTES.md            # no; `read` numbers the lines
sed -n 270,285p FILE    # no; `read` with offset 270 and limit 16
grep -rn "TODO" src     # no; one search habit, not two
rg -n "TODO" src        # no; same answer in a shape you can follow
find . -name "*.py"     # no; the `find` tool respects .gitignore
fd -e py                # no; the `find` tool answers the same list
ls src                  # no; the `ls` tool answers one entry per line
git diff | head -50     # yes; the cut belongs to the pipeline
fd -e py | xargs wc -l  # yes; the total has to be computed
```

Never pass a script through a heredoc or a long `-c` string: the script lands
in the transcript, where the `write` tool leaves the same file and only its
path here. One line is the exception.

```sh
python3 - <<'PY'         # no; the script lands in the transcript
cat > /tmp/m.py <<'EOF'  # no; same
python3 /tmp/m.py        # yes; the `write` tool first, then run it
python3 -c 'print(1)'    # yes; when one line is enough
```

Keep a chain short enough to read as one line of intent, and split it as soon as
its output needs untangling to see what ran.

```sh
git status && git diff  # yes; each half labels its own output
cat a.txt && cat b.txt  # no; two files, one unlabelled stream
```

Never add `2>/dev/null` or `|| true` to tidy a command: the first discards the
stream, the second the exit status, and both hide the error that mattered. Ask
the program for quiet instead, with `-q` or `--no-progress`.

```sh
make 2>/dev/null  # no; compiler errors arrive on stderr
git fetch -q      # yes; quiet from the program, not the shell
```

# Missing tools

If the tool you need is missing, say so and ask, instead of substituting a
shell scan for it.

# Language

- The user is a native Japanese speaker and gives instructions in Japanese or
  English, depending on the task's complexity or even their mood. Reply in the
  language of the user's instruction unless they say otherwise.
- Be direct and concise to save tokens.
- Prefer writing git-managed files in English, unless overridden by the project
  preference or user instructions.
