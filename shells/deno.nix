{ pkgs, neovim-flake, ... }:

let
  neovim = neovim-flake.neovim {
    modules = with neovim-flake; [
      core
      clipboard
      copilot
      deno
    ];
  };
in
{
  packages = with pkgs; [
    deno
    neovim
  ];
}
