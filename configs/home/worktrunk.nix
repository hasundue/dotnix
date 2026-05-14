{ pkgs, ... }:

{
  home.packages = [ pkgs.worktrunk ];

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
