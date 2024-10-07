{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      zoom-us
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
    ];
    config.zoom-us.default = [ "kde" ];
  };
}
