{ pkgs, ... }:
{
  home.packages = [ pkgs.worktrunk ];

  home.file.".config/worktrunk/config.toml".source = ./config.toml;

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
