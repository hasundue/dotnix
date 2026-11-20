{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    enableGhostscriptFonts = false;

    packages = with pkgs; [
      # Variable-width Japanese UI, including stylix sans/serif and Zed UI
      noto-fonts-cjk-sans

      plemoljp-nf

      # Symbol font retained for fallback use
      iosevka
    ];
  };
}
