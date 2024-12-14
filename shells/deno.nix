{ pkgs, ... }:

let
  inherit (pkgs) mkNeovim;

  neovim = mkNeovim {
    modules = with mkNeovim.modules; [
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
