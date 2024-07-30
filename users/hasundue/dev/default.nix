{ pkgs, lib, ... }:

with lib;

{
  imports = [
    ./deno.nix
    ./gh.nix
    ./nix.nix
    ./zed
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
