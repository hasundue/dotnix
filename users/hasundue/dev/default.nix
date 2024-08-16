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
      gcc
      nodejs
      (rust-bin.stable.latest.default.override {
        targets = [ "wasm32-unknown-unknown" ];
      })

      # tools
      act
      slides
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
