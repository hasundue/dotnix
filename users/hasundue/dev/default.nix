{ pkgs, lib, ... }:

with lib;

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
      devenv
    ];
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
