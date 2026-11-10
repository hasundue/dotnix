{ pkgs, ... }:
let
  originalImage = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/a/a5/Tsunami_by_hokusai_19th_century.jpg";
    hash = "sha256-MMFwJg3jk/Ub1ZKtrMbwcUtg8VfAl0TpxbbUbmphNxg=";
  };
  darkenedImage =
    pkgs.runCommand "darkened-wallpaper.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; }
      ''
        magick ${originalImage} -fill black -colorize 20% $out
      '';
in
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    cursor = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 24;
    };
    fonts = {
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
        popups = 12;
        terminal = 11;
      };
    };
    image = darkenedImage;
    opacity = {
      applications = 1;
      desktop = 0.98;
      popups = 0.9;
      terminal = 0.98;
    };
    polarity = "dark";
  };
}
