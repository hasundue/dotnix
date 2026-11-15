# Mako

Checked against mako 1.11.0. `makoctl help` is the authority for subcommands.

Mako is the notification daemon: every desktop notification on this setup ends
up in it. `makoctl list -j` is the JSON observation surface.

```sh
makoctl list -j                                   # active notifications
makoctl dismiss -n <id>                           # one, by id
makoctl dismiss -n <id> --no-history              # one, without archiving it
makoctl dismiss -a                                # all — never in a test
makoctl dismiss -g                                # the last group
makoctl history [-j]                              # dismissed, still in history
```

For `dismiss`, `-h` means `--no-history`, not help.

A listed notification carries `id`, `app_name`, `app_icon`, `desktop_entry`,
`summary`, `body`, `urgency`, and `actions`. The `id` is Mako's, so the list is
the only way to dismiss something specific.

## Timeouts

With the shipped config — no global `default-timeout` — the value is **0**, which
means notifications never expire on their own. Anything that disappears was
withdrawn by the sending program or dismissed by a helper; the exception is a
per-app override, written as a section:

```ini
[app-name=niri]
default-timeout=3000
```

So "the notification vanished" is first a question about the sender, then about
the config, and never about Mako quietly expiring it.

## Where the app name comes from

OSC 9 and OSC 777 have no app-name field, so a terminal that forwards them
supplies the identity instead: `desktop_entry` and `app_icon` carry
`com.mitchellh.ghostty` while `app_name` stays null. Matching on `app_name` alone
therefore misses terminal notifications — match `desktop_entry` too.

## Focus-based dismissal

Niri sends focus events to the compositor only, and Mako has no focus option, so
a helper outside both can bridge them: watch `niri msg --json event-stream`, and
when a window gains focus, dismiss the non-critical notifications whose name
matches that window's `app_id`. Name matching usually ignores case and
punctuation, so `google-chrome` matches "Google Chrome", with per-app exceptions
where the two sides disagree. Before blaming the sender for a notification that
vanished, look for such a helper (`systemctl --user list-units --type=service |
grep -i mako`) and read its journal.

That helper can only clear a notification _after_ it appears, so it does not
make a notification invisible to a user who is already looking at the window.

## Testing it

Leave the user's queue alone: identify your notification by a unique summary,
dismiss that id, and re-read the list to confirm. Clearing the queue to get a
clean baseline destroys information the user was relying on.
