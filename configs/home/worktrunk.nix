{ config, pkgs, ... }:
{
  home.packages = [ pkgs.worktrunk ];

  home.file.".config/worktrunk/config.toml".text = ''
    skip-shell-integration-prompt = true

    [merge]
    remove = false
    commit = false    # --no-commit by default

    [post-start]
    copy-envrc = "test -f {{ primary_worktree_path }}/.envrc && cp {{ primary_worktree_path }}/.envrc {{ worktree_path }}/.envrc"
  '';

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
