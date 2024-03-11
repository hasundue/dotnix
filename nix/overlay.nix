{ self, nixpkgs, devshell, neovim-nightly, nixpkgs-wayland, ... } @ inputs:

let
  inherit (nixpkgs) lib;

  local = lib.mapAttrs'
    (file: _: lib.nameValuePair
      (lib.removeSuffix ".nix" file)
      (lib.composeExtensions
        (_: _: { __inputs = inputs; })
        (import (./overlays + "/${file}"))
      )
    )
    (builtins.readDir (./overlays));
in
local // {
  default = lib.composeManyExtensions ([
    devshell.overlays.default
    neovim-nightly.overlays.default
    nixpkgs-wayland.overlays.default
  ] ++ (lib.attrValues local));
}
