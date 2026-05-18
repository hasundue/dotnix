{ pkgs, ... }:
{
  home.packages = [ pkgs.worktrunk ];

  home.file.".config/worktrunk/config.toml".text = ''
    skip-shell-integration-prompt = true

    [merge]
    remove = false

    [post-start]
    copy-envrc = "test -f {{ primary_worktree_path }}/.envrc && cp {{ primary_worktree_path }}/.envrc {{ worktree_path }}/.envrc"
    copy-rpiv = "test -d {{ primary_worktree_path }}/.rpiv && cp -r {{ primary_worktree_path }}/.rpiv {{ worktree_path }}/.rpiv"
  '';

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
