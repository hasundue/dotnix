---
name: niri
description: >
  Prove desktop behaviour on Niri without a human at the keyboard: name the
  window under test, move focus, watch notifications, and leave evidence that
  survives a second look. Use when an outcome is only visible on the desktop (a
  notification appeared, which window has focus, what a window is titled), when
  a change must be checked "end to end" in a graphical session, or when a test
  has to open and close real windows.
---

# Niri

This skill watches the desktop; it does not edit Niri's configuration. A
keybinding, layout, or theme change belongs in the config, while a claim about
what the desktop actually did belongs here.

A desktop change can only be called verified when the thing the user will see
was actually seen — and seeing it means the agent captured what the compositor
and the notification daemon reported, at the moment it happened. Two rules carry
this skill:

- **Poll, do not sample.** A state that lasts three seconds proves nothing when
  it is checked once, thirty seconds later.
- **Ask before taking the desktop.** Moving focus covers the user's work with a
  window they did not open.

Everything else is judgment.

`references/` holds the app-level facts. Each file names the versions it was
checked against, and those facts age: when one of them decides what to do —
whether a mechanism exists, which command to trust — confirm it against
`--help`, the source, or the live output first. A stale interface produces a
visible mismatch; a stale behavioural premise silently changes the plan.

## Prerequisites

Niri exports `NIRI_SOCKET` to every process it spawns, so its absence is proof
of no compositor:

```sh
[ -n "${NIRI_SOCKET:-}" ] && niri msg version
```

Without Niri — a container, WSL, an SSH session — there is nothing to verify
this way. Say so and stop; do not simulate the desktop or switch to
`notify-send` as a stand-in.

## Before taking focus

A focus change is visible, disruptive, and cannot be inferred from idle state,
so it is the user's call, not yours. Ask for it in these words or equivalent:
is now a safe time for windows to open and focus to move? Static checks, unit
tests, and reading a file need no permission.

When the answer is no, leave only the end-to-end criterion unverified and say
which one it is. Never ask the user to run the manual steps instead.

## Name the window

A window is identified by `id`, `pid`, `title`, and `app_id`, and only the first
is unique to the window. `pid` is the owning application, which may own several
windows, so a pid match says "our application is somewhere on screen", not "our
window has focus". Details: `references/ipc.md`.

Find the window you just spawned by diffing ids, then read its title:

```sh
base=$(niri msg --json windows | jq -c '[.[].id]')
niri msg action spawn -- ghostty --working-directory=/tmp -e <command...>

niri msg --json windows |
  jq -r --argjson base "$base" '.[] | select(.id as $x | ($base | index($x)) == null)
        | "\(.id)\t\(.pid)\t\(.title)"'
```

A title can lag the spawn by a second or two, so identify the window by id and
read the title again at the moment it matters — a title read during startup is
often the placeholder the terminal started with.

## Move focus, then put it back

```sh
before=$(niri msg --json focused-window | jq -r '.id')   # remember this
niri msg action focus-window --id <id>
niri msg --json focused-window | jq -r '.id'             # confirm, every time
niri msg action focus-window --id "$before"              # at the end, always
```

Confirming is not ceremony: a `focus-window` naming a window that has closed is
a silent no-op, and the next check then measures the wrong window.

## Observe

Snapshot, compare, and print only the transitions with timestamps:

```sh
prev=""
for _ in $(seq 1 150); do
  cur=$(makoctl list -j | jq -c '[.[] | {id, summary, body}]')
  now=$(date +%H:%M:%S.%3N)
  if [ "$cur" != "$prev" ]; then echo "$now $cur"; prev="$cur"; fi
  sleep 0.1
done
```

Ten seconds at roughly 100 ms per pass (each pass spawns `makoctl`, so the true
period is longer) is sized for a run that settles in a few seconds plus whatever
the terminal does to the notification afterwards. Print the settle time from the
subject's own log or session file next to the observation, so the two can be
lined up later.

## Leave evidence a reader can check

Record, in the report or the note:

- the window's identity (`id`, `pid`, `title`) as the compositor reported it
- the moment the event of interest happened, from the application's own record
- every transition of the observed state, with timestamps
- what proves each claim, and what was not checked

"Looked plausible" is not evidence. A claim that a quiet state was observed must
say how long it was watched and how often, because the interesting state may
have come and gone inside the window.

## Clean up, then verify the cleanup

1. Kill the test processes before closing their windows: a terminal holding a
   live child asks for confirmation and the window survives the close request.
2. Dismiss only your own notifications, by id and with `--no-history` so the
   test leaves nothing in the user's history, never `--all`: the queue is not
   yours to clear.
3. Return focus to the window that had it.
4. Re-read the state you changed — focused window id, window list, notification
   list — and report it. A cleanup nobody checked is a cleanup that may not have
   happened.

## Traps

- A focused notification may be shown and then withdrawn by the terminal itself
  rather than suppressed, so silence at +30 s says nothing about a notification
  at +1 s.
- A notification that disappears was withdrawn by its sender or dismissed by a
  helper; the daemon does not expire it on its own: `references/mako.md`.
- Pi's TUI title carries the session name and the directory name, which is
  usually the cheapest way to tell your window from another of the same
  terminal: `references/pi.md`.
- A window with a child process ignores a close request until the child exits.
- `niri msg` is JSON on stdout and human text without `--json`; parse the JSON.
- Two terminals may share one process, and one window may hold several surfaces;
  neither pid nor app id identifies the surface that emitted something.
