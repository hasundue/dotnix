{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      slack
    ];
    shellAliases = {
      slack = "slack --enable-wayland-ime";
    };
  };
}
