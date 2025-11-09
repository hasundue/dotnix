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
}
