# Live configuration

Here, a live configuration means a feature's configuration directory selected
by `dotnix.live.<name>.enable`. Currently this is Pi's
`configs/home/pi/agent`; `~/dotnix.live.pi` resolves to that directory, whose
links point into the activation's checkout instead of the store.

## Checkout selection and activation

Activation, not the build, decides which checkout owns the live tree:

- `nix run .#home-live` exports `DOTNIX_LIVE_ROOT` and moves the live tree to
  the checkout where it ran. This affects reads and writes alike.
- `home-switch` and the activating NixOS apps (`nixos-test` and
  `nixos-switch`) put the tree back on `~/dotnix`.
- `home-build`, `nixos-build`, and `nixos-boot` do not activate, so they move
  nothing.

A feature that writes configuration therefore dirties the checkout it was
activated from.

## Removing a worktree that owns the live tree

The `.config/wt.toml` `pre-remove` hook repoints the live link to `~/dotnix`
before a live worktree is removed. Worktrunk asks for approval to run that
project command and refuses to proceed non-interactively until it is approved;
ask for the approval rather than working around it.

Removing a worktree another way, or with `--no-hooks`, leaves the live links
dangling until the next activation.
