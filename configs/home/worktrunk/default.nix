{ pkgs, ... }:
let
  # Hook helpers: store-path binaries, deliberately not in home.packages, so
  # they stay out of the user's PATH. The generated config below embeds their
  # store paths in the hook commands, and no hook body is more than one line,
  # which keeps Worktrunk's hook echoes short.

  # copy-pi-settings gives a new worktree the primary checkout's
  # .pi/settings.json, which git ignores: without it pi loses the project's
  # packages (pi-worktrunk, for one). It copies only when the source exists
  # and the target does not, so a checkout that deliberately dropped its own
  # copy keeps it.
  copy-pi-settings = pkgs.writeShellApplication {
    name = "copy-pi-settings";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./copy-pi-settings.sh;
  };

  # install-git-hooks links the repository's pre-commit config into a new
  # worktree without building the whole dev shell. It no-ops where the flake
  # has no `pre-commit-config` package.
  install-git-hooks = pkgs.writeShellApplication {
    name = "install-git-hooks";
    runtimeInputs = [ pkgs.nix ];
    text = builtins.readFile ./install-git-hooks.sh;
  };

  # The user Worktrunk config, generated so hook commands can carry store
  # paths. The {{ ... }} in hook commands are Worktrunk template variables;
  # Worktrunk shell-escapes each substituted path, so a hook may quote it.
  configTOML = ''
    skip-shell-integration-prompt = true

    [merge]
    commit = false    # --no-commit by default
  ''
  # A worktree starts from a commit, so a file git ignores is missing there.
  # Both copy helpers work in every repository, so neither asks a repository
  # to opt in. The second block runs after the copies: direnv needs .envrc,
  # and git hooks need the config.
  + ''
    [[post-start]]
    copy-envrc = "if test -f {{ primary_worktree_path }}/.envrc; then cp {{ primary_worktree_path }}/.envrc {{ worktree_path }}/.envrc; fi"
    copy-pi-settings = "${copy-pi-settings}/bin/copy-pi-settings {{ primary_worktree_path }}/.pi/settings.json {{ worktree_path }}/.pi/settings.json"

    [[post-start]]
    setup = "if test -f .envrc; then direnv allow; fi; ${install-git-hooks}/bin/install-git-hooks"
  '';
in
{
  home.packages = [ pkgs.worktrunk ];

  home.file.".config/worktrunk/config.toml".text = configTOML;

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
