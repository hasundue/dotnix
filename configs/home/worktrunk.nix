{ pkgs, ... }:
{
  home.packages = [ pkgs.worktrunk ];

  home.file.".config/worktrunk/config.toml".text = ''
    skip-shell-integration-prompt = true

    [merge]
    remove = false
  '';

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
