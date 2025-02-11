{ pkgs, ... }:

let
  inherit (pkgs) mkNeovim;
  inherit (pkgs.lib) getLib;

  neovim = mkNeovim {
    modules = with mkNeovim.modules; [
      core
      clipboard
      copilot
    ];
  };
in
{
  nativeBuildInputs = with pkgs; [
    libGL
    xorg.libX11
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXinerama
    xorg.libXi
    xorg.libXxf86vm
  ];

  packages = with pkgs; [
    go
    neovim
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.wayland}/lib:${getLib pkgs.libGL}/lib:$LD_LIBRARY_PATH
  '';
}
