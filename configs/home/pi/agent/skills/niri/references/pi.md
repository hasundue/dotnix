# Pi in a terminal

Checked against pi 1.5.2; the CLI and title format are Pi's own interface, so
`pi --help` and the source named below are the authority when something
disagrees.

Pi's TUI sets the terminal title to its session name and directory, which is
usually the cheapest way to tell which window is which:

```
<APP_TITLE> - <session name> - <cwd basename>     named session
<APP_TITLE> - <cwd basename>                      unnamed session
```

`APP_TITLE` is `π` unless the install renames the binary. Titles are set in
interactive mode only (`dist/modes/interactive/interactive-mode.js`), and a
title read a moment after spawn can still be the terminal's own placeholder, so
read it again after the first frame.

## What runs where

- `pi` — TUI, terminal-only features active, `ctx.mode === "tui"`.
- `pi -p` / `--mode json` — one run, prints and exits, no TUI, and extensions
  guarded by `ctx.mode` skip terminal-only work.
- `pi --mode rpc` — driven by another process over a protocol stream.

`--name <name>` sets the session name up front. Without it, a naming extension
may fill the name in a few seconds later, so an unnamed session is hard to
produce on purpose — test the fallback elsewhere.

## Where Pi reads extensions and skills

`~/.pi/agent/extensions` and `~/.pi/agent/skills` are the discovery points. Where
those are symlinks into a checkout, an edit is live for the _next_ process, not
the current one. A running Pi keeps the code it started with: `/reload` rereads
extensions, skills, templates, and context files; a restart is the alternative.
A notification that appears after an edit may simply be the old code still
running.

Both directories answer to settings: every `*.ts` in the extensions directory
loads, and every `skills/*/SKILL.md` is available unless the `skills` setting
drops it — an installation can hide skills by default, and a project re-adds one
from its own `.pi/settings.json`. A skill edit needs `/reload` too.

## Testing a Pi feature on the desktop

```sh
niri msg action spawn -- ghostty --working-directory=/tmp -e \
  pi --no-mcp -nt --model <provider>/<model> --name <unique-name> \
  --session-dir /tmp/<run>/sessions "<prompt>"
```

`--no-session` writes no transcript; a `--session-dir` keeps one, and the last
entry's `timestamp` marks the end of the run's last model output — an anchor for
timing claims that lands a moment before the settle event itself.
`--no-mcp` and `-nt` keep a test run short and offline-ish. A unique `--name`
both identifies the window (the title carries it) and keeps the notification
summary distinguishable from everything else.
