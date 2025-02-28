{ pkgs, lib, ... }:

pkgs.mkShell {
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
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.wayland}/lib:${lib.getLib pkgs.libGL}/lib:$LD_LIBRARY_PATH
  '';
}
