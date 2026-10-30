# SPEC -- Serve pi's configuration live from the dotnix worktree

## Goal

pi's configuration files (`AGENTS.md`, `APPEND_SYSTEM.md`, `models.json`,
`prompts/`, `themes/`, `extensions/`, `skills/`) move into dotnix and are served
to `~/.pi/agent` as symlinks into the dotnix working tree, so editing them takes
effect without a rebuild. `~/.pi/agent` stops being a git checkout and becomes a
local runtime directory that also holds pi's state. Which checkout supplies the
live files becomes an explicit Nix option, and a host without that checkout
fails the switch instead of silently producing a broken home.

## Background

State of `main` at `1da9c02`:

- `configs/home/pi.nix` enables `programs.pi-coding-agent` and puts the PDF
  toolchain in `extraPackages`. It declares no configuration files; its comment
  says settings/models/keybindings/context/appendSystem are deliberately unset
  because the directory belongs to the `pi-config` repository.
- `~/.pi/agent` is a real directory and a git clone of
  `github.com:hasundue/pi-config`. 20 tracked files: `AGENTS.md`,
  `APPEND_SYSTEM.md`, `models.json`, `settings.json`, `prompts/polish.md`,
  `themes/kanagawa-wave.json`, `extensions/temperature.ts`, and 7 skills under
  `skills/`. Its `.gitignore` excludes `auth.json`, `trust.json`,
  `models-store.json`, `sessions/`, `bin/`, `npm/`, `git/`, `tmp/`, `*.backup`,
  `*.log`, `node_modules/`, `deno.lock`.
- `settings.json` is written by pi itself (`/settings`, `pi update`) and holds
  `lastChangelogVersion`, which changes when pi is updated. Nix must not own it.
- home-manager's `programs.pi-coding-agent` can write `settings.json`,
  `keybindings.json`, `models.json`, `AGENTS.md`, and `APPEND_SYSTEM.md` as
  individual files under `configDir` (default `~/.pi/agent`). It does not manage
  `skills/`, `prompts/`, `themes/`, or `extensions/`.
- `mkOutOfStoreSymlink` is implemented as
  `pkgs.runCommandLocal name {} "ln -s <absolute path> $out"`. The target's
  existence is not checked at build time, so a missing checkout yields a
  successful build and a dangling symlink after activation.
- `configs/home/pi/` currently contains only ignored leftovers, `deno.lock` and
  `node_modules/` (539 MB). Both are disposable.
- `~/dotnix` is always on `main`; feature work happens in `~/dotnix.<branch>`
  worktrees (`dotnix.artifacts`, `dotnix.audio-switcher`,
  `dotnix.audio-switcher-impl`, `dotnix.zotero-mcp`).
- dotnix has no `dotnix.*` option namespace yet. `configs/home/default.nix`
  imports `./pi.nix`; nothing else references it.

Decisions taken while designing this (reasons are load-bearing):

1. **Do not symlink the whole `~/.pi/agent` directory.** pi writes
   `settings.json` there and keeps `sessions/`, `auth.json`, `trust.json`, and
   `models-store.json` in the same directory. Pointing the directory at a git
   worktree would dirty the repository during normal use, let a branch switch
   reconfigure a running agent, and put credentials inside the dotnix tree.
2. **Symlink individual entries instead**, and keep state local.
3. **Introduce `dotnix.live.<name>`** so the checkout location is declared once
   per feature. Consumers reference the stable path `~/dotnix.live.<name>` and
   never mention `~/dotnix`. nvim can later use
   `dotnix.live.nvim.root = "${home}/nvim"` without touching pi.
4. **Fall back to a store copy when disabled.** With
   `dotnix.live.<name>.enable = false`, `~/dotnix.live.<name>` points at the
   store copy of the same files, so the consumer-side links never change and the
   configuration stays reproducible.
5. **Verify the checkout during activation, not at evaluation.** Evaluation-time
   checks are impossible: `builtins.pathExists` returns `false` for out-of-store
   paths under pure evaluation (silently, not as an error), and
   `types.path.check` accepts paths that do not exist. The check must run before
   `writeBoundary` so that a failed activation leaves the previous generation's
   links intact.
6. **Leave `settings.json` alone.** No `settings` option, no
   `mutableSettings = true`. pi keeps owning the file, and it stays a plain
   local file in `~/.pi/agent`.
7. **Do not create a separate worktree for the live copy yet.** A worktree of
   the same repository shares `.git`, so no push or pull is involved, but git
   forbids two worktrees on one branch, which forces a dedicated branch and
   ping-pong merges. `~/dotnix` is pinned to `main` in practice, so the
   branch-switch risk is already small. Because the checkout is an option,
   promoting `~/dotnix.live.pi` to a worktree later changes one line.
8. **`models.json` stays inside the live directory.** It is plain data with a
   `$schema` field that the `models` option would strip, and keeping it in the
   live directory makes the mapping "every entry in `configs/home/pi/agent/` is
   symlinked into `~/.pi/agent/`" exact. The `models` option is not used.

## Target layout

```
configs/home/live.nix                 new: dotnix.live option + activation check
configs/home/pi/default.nix           moved from configs/home/pi.nix, adds links
configs/home/pi/agent/AGENTS.md       moved from ~/.pi/agent/AGENTS.md
configs/home/pi/agent/APPEND_SYSTEM.md
configs/home/pi/agent/models.json
configs/home/pi/agent/prompts/polish.md
configs/home/pi/agent/themes/kanagawa-wave.json
configs/home/pi/agent/extensions/temperature.ts
configs/home/pi/agent/skills/**       7 skills, moved from ~/.pi/agent/skills
configs/home/default.nix              import ./pi.nix -> ./pi
```

`configs/home/pi/agent/` is exactly the live subset. After the switch,
`~/.pi/agent` contains:

| Entry                                                                                                                 | Kind                                  |
| --------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `AGENTS.md`, `APPEND_SYSTEM.md`, `models.json`, `prompts/`, `themes/`, `extensions/`, `skills/`                       | symlink to `~/dotnix.live.pi/<entry>` |
| `settings.json`, `auth.json`, `trust.json`, `models-store.json`, `sessions/`, `bin/`, `npm/`, `git/`, `tmp/`, `*.log` | local, untouched by Nix               |

## Option shape

```nix
options.dotnix.live = mkOption {
  type = types.attrsOf (types.submodule ({ name, ... }: {
    options = {
      enable = mkEnableOption "live configuration for ${name}";
      root = mkOption {
        type = types.str;   # NOT types.path: interpolation copies paths to the store
        default = "${config.home.homeDirectory}/dotnix";
      };
      path = mkOption {
        type = types.str;
        default = "configs/home/${name}";
      };
      stable = mkOption {
        type = types.str;
        readOnly = true;
        default = "${config.home.homeDirectory}/dotnix.live.${name}";
      };
    };
  }));
  default = { };
};
```

`root` must be `types.str`. A `types.path` value is copied into the store when
interpolated into a string, which would make the link point at read-only store
content.

Activation check, in `configs/home/live.nix`:

```nix
home.activation.dotnixLiveCheck = lib.hm.dag.entryBefore [ "writeBoundary" ] (
  lib.concatStrings (lib.mapAttrsToList (name: f: lib.mkIf f.enable ''
    [ -d ${lib.escapeShellArg "${f.root}/${f.path}"} ] || {
      echo "error: dotnix.live.${name}.enable = true but ${f.root}/${f.path} is missing." >&2
      echo "  fix: check out dotnix there, set dotnix.live.${name}.root, or disable it." >&2
      exit 1
    }
  '') config.dotnix.live)
);
```

pi module sketch (`configs/home/pi/default.nix`):

```nix
let
  live = config.dotnix.live.pi;
  link = p: config.lib.file.mkOutOfStoreSymlink "${live.stable}/${p}";
in
{
  dotnix.live.pi = {
    enable = true;
    path = "configs/home/pi/agent";
  };

  home.file = {
    "dotnix.live.pi".source =
      if live.enable
      then config.lib.file.mkOutOfStoreSymlink "${live.root}/${live.path}"
      else ./agent;

    ".pi/agent/AGENTS.md".source = link "AGENTS.md";
    ".pi/agent/APPEND_SYSTEM.md".source = link "APPEND_SYSTEM.md";
    ".pi/agent/models.json".source = link "models.json";
    ".pi/agent/prompts".source = link "prompts";
    ".pi/agent/themes".source = link "themes";
    ".pi/agent/extensions".source = link "extensions";
    ".pi/agent/skills".source = link "skills";
  };
}
```

## Migration on a host that already has `~/.pi/agent`

Home-manager refuses to overwrite existing files, so the old directory must move
first. State is preserved by copying it back.

```bash
# 1. after the branch is merged and pulled
mv ~/.pi/agent ~/.pi/agent.pre-live

# 2. create the links
nix run .#home-build && nix run .#home-switch

# 3. restore local state that is not in dotnix
for f in settings.json auth.json trust.json models-store.json sessions bin npm git tmp; do
  [ -e ~/.pi/agent.pre-live/"$f" ] && [ ! -e ~/.pi/agent/"$f" ] && \
    cp -a ~/.pi/agent.pre-live/"$f" ~/.pi/agent/
done

# 4. verify, then remove the backup
```

On WSL, run the same steps after `git pull` and `nix run .#nixos-switch`. If
`auth.json` is absent, run `pi /login`.

## Acceptance criteria

- [ ] `dotnix.live.pi.stable` evaluates to `~/dotnix.live.pi` verify:
      `nix eval --raw .#homeConfigurations."hasundue@x1carbon".config.dotnix.live.pi.stable`
      prints `/home/hasundue/dotnix.live.pi`
- [ ] The home configuration evaluates and builds verify: `nix run .#home-build`
      exits 0
- [ ] `~/.pi/agent/skills` resolves into the dotnix working tree verify:
      `readlink -f ~/.pi/agent/skills` prints
      `/home/hasundue/dotnix/configs/home/pi/agent/skills`
- [ ] Editing a file in dotnix reaches pi without a rebuild verify:
      `echo '# probe' >> configs/home/pi/agent/skills/agent-skills/SKILL.md`
      then `tail -1 ~/.pi/agent/skills/agent-skills/SKILL.md` prints `# probe`
      (revert the edit afterwards)
- [ ] `settings.json` remains a local writable file, and `~/.pi/agent` is no
      longer a git checkout verify:
      `test -f ~/.pi/agent/settings.json && ! test -L ~/.pi/agent/settings.json`
      and `git -C ~/.pi/agent rev-parse --is-inside-work-tree` fails
- [ ] `dotnix.live.pi.enable = false` falls back to the store copy verify:
      temporarily set it to `false`, run `nix run .#home-build`,
      `nix run .#home-switch`, then `readlink -f ~/.pi/agent/skills` starts with
      `/nix/store/`; revert afterwards
- [ ] A missing checkout fails the switch before any link is written, and the
      previous generation's links survive verify: temporarily set
      `dotnix.live.pi.root = "/nonexistent"`, build, run
      `nix run .#home-switch`; it exits non-zero with a message containing
      `dotnix.live.pi`, and `readlink -f ~/.pi/agent/skills` still prints the
      pre-failure target; revert afterwards
- [ ] pi starts with the migrated configuration verify: run `pi`, confirm the
      skill commands (`/skill:keel`, `/skill:pdf-tools`, ...) are offered and
      `AGENTS.md` is loaded
- [ ] The WSL host reaches the same state after `git pull` and
      `nix run .#nixos-switch` verify: the `skills` link and `settings.json`
      checks above on that host

## Out of scope

- Migrating nvim's Lua to the live mechanism. That requires a wrapper variant in
  `hasundue/nvim` that does not bake `runtimepath` from the store, which is a
  different repository and a different flake input.
- Any Nix management of `~/.pi/agent`'s state (`sessions/`, `auth.json`,
  `trust.json`, `models-store.json`).
- Declaring `settings.json` from Nix, or using `mutableSettings`.
- Deleting or archiving the `pi-config` repository. Its remote is left as is.
- Applying `dotnix.live` to anything other than pi. The mechanism is generic;
  only pi is migrated.
- Promoting `~/dotnix.live.pi` to an independent worktree.
- Changing `flake.nix` inputs or adding `extraSpecialArgs`.

## Stop conditions

- The same activation failure twice -> write the cause under `## Blocker`, stop
- The work needs a change in `hasundue/nvim` or in pi itself -> stop
- A file in `~/.pi/agent` cannot be classified as configuration or state -> stop
  and ask
- Touching `configs/hosts/*`, `overlays/`, `packages/`, or `flake.nix` inputs ->
  stop
- More than 6 files changed outside `configs/home/pi/` and
  `configs/home/live.nix` -> stop and report

## Decisions

- 2026-10-30 -- symlink individual config entries, not the agent directory -- pi
  writes `settings.json` and keeps state in the same directory, so a directory
  symlink would dirty the repo and mix credentials into it
- 2026-10-30 -- `dotnix.live.<name>` with a stable path -- confines the checkout
  assumption to one option per feature and lets nvim point elsewhere later
- 2026-10-30 -- activation check before `writeBoundary` -- evaluation-time
  existence checks are impossible without impurity, and a late check would leave
  dangling links behind
- 2026-10-30 -- `settings.json` stays local -- it holds `lastChangelogVersion`,
  which pi rewrites on update
- 2026-10-30 -- no worktree for the live copy -- a same-repo worktree shares
  `.git` but cannot share a branch, so it costs merges without removing a risk
  that `~/dotnix` being pinned to `main` already removes

## Confirmed

- 2026-10-30 -- user: "yes"

## Notes

- `~/.pi/agent` also contains `pi-crash.log` and `*.backup` files; they are
  local artifacts and are neither migrated nor managed.
- The 539 MB `configs/home/pi/node_modules` and `configs/home/pi/deno.lock` are
  leftovers from an earlier layout and are deleted as part of this work.
- `programs.pi-coding-agent.configDir` stays at its default, so
  `PI_CODING_AGENT_DIR` is not exported.
