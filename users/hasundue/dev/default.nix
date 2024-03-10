{ pkgs, ... }:

{
  imports = [
    ./deno.nix
  ];

  home = {
    packages = with pkgs; [
      # runtimes
      bun
      nodejs
      nodePackages.yarn
      zig

      # tools
      act
      gh
      lazygit
    ];
  };

  programs.gitui = {
    enable = true;
    keyConfig = builtins.readFile ./gitui.ron;
  };
}
