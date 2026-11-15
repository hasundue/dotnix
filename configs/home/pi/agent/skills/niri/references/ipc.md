# Niri IPC

Checked against niri 26.04. `niri msg --help` and `niri msg --json windows |
jq '.[0] | keys'` are the authority for actions and fields; a renamed field
makes a filter return null rather than fail, so read the output of a new filter
before trusting it.

Everything goes through `niri msg`. JSON output needs `--json` **before** the
subject, not after:

```sh
niri msg --json windows          # yes
niri msg windows --json          # no
```

`niri msg version` is the cheap liveness check; the socket path in
`NIRI_SOCKET` is what a spawned process inherits, so a session that has it can
talk to the compositor even if it cannot see the screen.

## What a window is

`niri msg --json windows` returns an array of:

| field                                                    | meaning                                                          |
| -------------------------------------------------------- | ---------------------------------------------------------------- |
| `id`                                                     | the only per-window identifier; use it everywhere                |
| `title`                                                  | the title the surface last set, updated after the window appears |
| `app_id`                                                 | the application, e.g. `com.mitchellh.ghostty`                    |
| `pid`                                                    | the owning process — **not** the window                          |
| `workspace_id`, `is_focused`, `is_floating`, `is_urgent` | state                                                            |
| `focus_timestamp`                                        | monotonic seconds/nanos of the last focus gain                   |
| `layout`                                                 | tile and window geometry                                         |

`niri msg --json focused-window` returns one such object, or nothing when no
window has focus — code that parses it must tolerate a null.

The consequence of `pid` being the process: one terminal process owns every
window it opened, so `pid` narrows a search to "some window of our application"
and nothing more. To name one window, use its title, its id, or a diff of the id
list before and after spawning. `focus_timestamp` answers "did focus move during
my observation", but it is monotonic since compositor start, not wall clock.

## Actions used for verification

```sh
niri msg action spawn -- <command> <args...>   # spawn, inherits NIRI_SOCKET
niri msg action focus-window --id <id>
niri msg action close-window --id <id>         # a request, not a kill
niri msg action move-window-to-workspace --window-id <id> <n>
```

`focus-window` with an id that no longer exists is a silent no-op, so read
`focused-window` back instead of assuming the move happened. `close-window` asks
the client to close; a terminal with a live child shows a confirmation and stays
open until the child exits, which is why a test harness kills its own children
first.

## Watching instead of polling

`niri msg --json event-stream` emits one JSON object per line (`WindowsChanged`,
`WindowOpenedOrChanged`, `WindowClosed`, `WindowFocusChanged`, ...). Use it for a
long-running helper that must react to focus, and polling for a bounded test that
must record transitions with timestamps.

## Reading the environment

`NIRI_SOCKET` is set for every process Niri spawns, which makes it the exact
test for "is a compositor available to ask". `XDG_CURRENT_DESKTOP=niri` says
which desktop it is; neither is a substitute for `niri msg version` when the
socket could be stale.
