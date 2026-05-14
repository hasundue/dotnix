{ pkgs, ... }:
{
  home.packages = [ pkgs.worktrunk ];

  home.file = {
    ".pi/agent/skills/worktrunk".source = pkgs.worktrunk-src + "/skills/worktrunk";
    ".pi/agent/skills/wt-switch-create".source = pkgs.worktrunk-src + "/skills/wt-switch-create";
  };

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
