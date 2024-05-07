{ pkgs, ... }:

{
  imports = [
    ./deno.nix
    ./gh.nix
  ];

  home = {
    packages = with pkgs; [
      # compilers and runtimes
      bun
      gcc
      nodejs
      rustup
      zig

      # tools
      act
      lazygit
    ];
  };

  programs.gitui = {
    enable = true;
    keyConfig = builtins.readFile ./gitui.ron;
  };
}
