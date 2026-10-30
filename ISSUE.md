# ISSUE -- Configuration deployment is either "all Nix" or "clone a repo by hand"

## What's wrong

pi's configuration lives at `~/.pi/agent`, outside dotnix's control. That
directory is a git clone of `github.com:hasundue/pi-config`; Nix manages only
the `pi` binary and its `extraPackages`. `configs/home/pi.nix` says so in a
comment: "Configuration (~/.pi/agent) stays under the pi-config repository, so
settings / models / keybindings / context / appendSystem are left unset."

Consequences:

- A new host needs `git clone ... ~/.pi/agent` by hand. Switching dotnix does
  not bring pi's configuration along.
- Configuration changes must be `git pull`ed separately on every host. x1carbon
  and WSL both need the same manual step.
- Nix cannot tell whether `~/.pi/agent` is a checkout at all, so a forgotten
  clone still produces a successful switch and a pi with empty configuration.

nvim sits at the opposite extreme: configuration is fully Nix-managed.
`hasundue/nvim`'s `pkgs/wrapper.nix` bakes the Lua tree into the store with
`lib.fileset.toSource ../nvim` and adds it to `runtimepath`, so changing one
line requires commit, `nix flake update nvim`, and a rebuild.

So configuration deployment is a choice between "store, rebuild every time" and
"outside Nix, clone and pull by hand". There is nothing in between, and neither
extreme states where the live copy actually comes from.

## Who feels it, and when

The owner of dotnix, on both x1carbon and the WSL host, whenever pi settings
change or when tweaking nvim Lua. Also on any future host: the setup step is
undocumented tribal knowledge rather than something the configuration carries.

## What was tried

`modules/home/rpiv-sync/default.nix` (removed in commit cea483a) kept a shared
git repository at `~/.local/share/rpiv`, symlinked each project's `.rpiv/` into
it, and ran a systemd timer that auto-committed every five minutes. It carried
214 lines of migration logic and timer units; the machinery became the
maintenance burden it was meant to remove.

## What "fixed" looks like -- in the user's words

> "nvim は完全に nix で管理しているのだけどそうすると日々の調整が大変"

> "pi-config は独立レポジトリにしてみたけどそうするとやはり WSL
> の環境で同期を取るのが面倒くさい"

> "home にある dotnix レポジトリの存在を暗に前提にしている"

## Open questions

- Where does `~/.pi/agent`'s runtime state (`sessions/`, `auth.json`,
  `trust.json`, `models-store.json`) belong once the directory is no longer a
  checkout?
- What should happen on a host that has no dotnix checkout, such as CI or a
  fresh machine?
