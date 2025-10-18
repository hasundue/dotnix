{ pkgs, ... }:

let
  originalImage = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/a/a5/Tsunami_by_hokusai_19th_century.jpg";
    hash = "sha256-MMFwJg3jk/Ub1ZKtrMbwcUtg8VfAl0TpxbbUbmphNxg=";
  };

  darkenedImage =
    pkgs.runCommand "darkened-wallpaper.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; }
      ''
        magick ${originalImage} -fill black -colorize 40% $out
      '';
in
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    image = darkenedImage;
    polarity = "dark";
  };
}
