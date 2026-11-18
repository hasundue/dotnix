{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    enableGhostscriptFonts = false;

    packages = with pkgs; [
      # Fallback for monospaced CJK characters
      noto-fonts-cjk-sans

      # Symbol font for Ghostty's `font-codepoint-map`
      # (configs/home/desktop/ghostty.nix), so that arrows, geometric shapes
      # and dingbats all come from one face with full coverage instead of
      # scattering across DejaVu, Noto Emoji and Unifont.
      iosevka
    ];
    fontconfig.defaultFonts.monospace = [
      "Noto Sans Mono CJK JP"
    ];
  };
}
