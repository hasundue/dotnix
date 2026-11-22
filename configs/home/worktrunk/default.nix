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

  # The user Worktrunk config, generated so hook commands can carry store
  # paths. The {{ ... }} in hook commands are Worktrunk template variables;
  # Worktrunk shell-escapes each substituted path, so a hook may quote it.
  configTOML = ''
    skip-shell-integration-prompt = true

    [merge]
    commit = false    # --no-commit by default
  ''
  # A worktree starts from a commit, so a file git ignores is missing there.
  # Both helpers work in every repository, so neither asks a repository to
  # opt in.
  + ''
    [post-start]
    copy-envrc = "test -f {{ primary_worktree_path }}/.envrc && cp {{ primary_worktree_path }}/.envrc {{ worktree_path }}/.envrc"
    copy-pi-settings = "${copy-pi-settings}/bin/copy-pi-settings {{ primary_worktree_path }}/.pi/settings.json {{ worktree_path }}/.pi/settings.json"
  '';
in
{
  home.packages = [ pkgs.worktrunk ];

  home.file.".config/worktrunk/config.toml".text = configTOML;

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
