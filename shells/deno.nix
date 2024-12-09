{ pkgs, neovim-flake, ... }:

let
  neovim = neovim-flake.mkNeovim {
    modules = with neovim-flake; [
      core
      clipboard
      copilot
      deno
    ];
  };
in
{
  aliases = rec {
    nv = "nvim";

    dt = "deno task";
    dtr = "${dt} run";
    dtt = "${dt} test";
  };
  packages = with pkgs; [
    deno
    neovim
  ];
}
