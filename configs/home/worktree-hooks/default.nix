{ lib, ... }:
let
  # Each group is one ordered Worktrunk `post-start` step. `stages` says which
  # Herdr events also run it: `create` for worktree.created and `open` for
  # worktree.opened. Bodies use WT_PRIMARY, WT_WORKTREE and WT_BRANCH so both
  # backends supply the same values. A worktree starts from a commit, so a file
  # git ignores is missing there; neither copy step asks a repository to opt in.
  groups = [
    {
      stages = [
        "create"
        "open"
      ];
      hooks = {
        copy-envrc = ''
          if test -f "$WT_PRIMARY/.envrc"; then
            cp "$WT_PRIMARY/.envrc" "$WT_WORKTREE/.envrc"
          fi
        '';
        copy-pi-settings = ''
          if test -f "$WT_PRIMARY/.pi/settings.json" && test ! -e "$WT_WORKTREE/.pi/settings.json"; then
            mkdir -p "$WT_WORKTREE/.pi"
            cp "$WT_PRIMARY/.pi/settings.json" "$WT_WORKTREE/.pi/settings.json"
          fi
        '';
      };
    }
    {
      stages = [ "create" ];
      hooks = {
        setup = ''
          if test -f .envrc; then
            direnv allow
          fi
          if test -f flake.nix; then
            config=$(nix eval --raw .#pre-commit-config 2>/dev/null || true)
            if test -n "$config"; then
              nix build --no-link .#pre-commit-config
              ln -sfn "$config" .pre-commit-config.yaml
            fi
          fi
        '';
      };
    }
  ];

  # Worktrunk shell-escapes these substitutions, so leave the quotes off.
  worktrunkPrelude = ''
    WT_PRIMARY={{ primary_worktree_path }}
    WT_WORKTREE={{ worktree_path }}
    export WT_PRIMARY WT_WORKTREE
    cd "$WT_WORKTREE"
  '';

  worktrunk = map (group: lib.mapAttrs (_: body: worktrunkPrelude + body) group.hooks) (
    lib.filter (group: lib.elem "create" group.stages) groups
  );

  functionName = name: "hook_" + lib.replaceStrings [ "-" ] [ "_" ] name;

  functions = lib.concatStringsSep "\n" (
    lib.concatMap (
      group:
      lib.mapAttrsToList (name: body: ''
        ${functionName name}() {
          ${body}
        }
      '') group.hooks
    ) groups
  );

  callsFor =
    stage:
    lib.concatStringsSep "\n" (
      lib.concatMap (
        group:
        if lib.elem stage group.stages then
          lib.mapAttrsToList (name: _: "          ${functionName name}") group.hooks
        else
          [ ]
      ) groups
    );

  cases = lib.concatStringsSep "\n" (
    map
      ({ stage, event }: ''
        ${event})
          ${callsFor stage}
          ;;
      '')
      [
        {
          stage = "create";
          event = "created";
        }
        {
          stage = "open";
          event = "opened";
        }
      ]
  );
in
{
  inherit worktrunk functions cases;
}
