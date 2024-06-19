{ pkgs, ... }:

{
  imports = [
    ./deno.nix
    ./gh.nix
    ./nix.nix
  ];

  home = {
    packages = with pkgs; [
      # compilers and runtimes
      bun
      cargo
      gcc
      nodejs
      zig

      # tools
      act
    ];
  };

  programs.gitui = {
    enable = true;
    keyConfig = builtins.readFile ./gitui.ron;
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        sidePanelWidth = 0.5;
      };
    };
  };
}
