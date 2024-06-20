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
    ];
  };

  programs = {
    direnv = {
      enable = true;
      config = {
        silent = true;
      };
    };
  };
}
