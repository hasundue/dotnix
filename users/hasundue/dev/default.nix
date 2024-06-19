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
}
