{ pkgs, srcs, ... }:

let
  inherit (pkgs.vimUtils) buildVimPlugin;
in
pkgs.vimPlugins // {
  incline-nvim = buildVimPlugin {
    pname = "incline-nvim";
    version = srcs.incline-nvim.rev;
    src = srcs.incline-nvim;
  };
}
