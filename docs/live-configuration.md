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

The user `pre-remove` hook (`rehome-live`, installed by the worktrunk config)
repoints the live link to the primary checkout before a live worktree is
removed. It is a user hook, so it runs without approval and in every
repository, no-oping where no `dotnix.live.*` link points into the removed
worktree.

Removing a worktree another way, or with `--no-hooks`, leaves the live links
dangling until the next activation.
