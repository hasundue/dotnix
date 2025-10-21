{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    enableGhostscriptFonts = false;

    # Fallback for monospaced CJK characters
    packages = with pkgs; [
      noto-fonts-cjk-sans
    ];
    fontconfig.defaultFonts.monospace = [
      "Noto Sans Mono CJK JP"
    ];
  };

  stylix.fonts = {
    sansSerif = {
      package = pkgs.noto-fonts-cjk-sans;
      name = "Noto Sans CJK JP";
    };
    serif = {
      package = pkgs.noto-fonts-cjk-serif;
      name = "Noto Serif CJK JP";
    };
    monospace = {
      package = pkgs.nerd-fonts._0xproto;
      name = "0xProto Nerd Font";
    };
    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
    sizes = {
      applications = 12;
      desktop = 12;
      popups = 13;
      terminal = 12;
    };
  };
}
