{ pkgs, ... }:
let
  # GPUI draws every glyph with empty font variations, so a variable font comes
  # out in its default instance. nixpkgs' Noto Sans CJK VF defaults to
  # wght=100 (Thin), which makes Japanese body text hairline thin, while
  # fontconfig-based applications get the Regular instance. GPUI's face
  # matching does prefer the closest weight, so handing it the static Regular
  # face is enough for it to settle on wght=400.
  cjkRegular = pkgs.runCommandLocal "waku-cjk-regular" { } ''
    mkdir -p $out/share/fonts
    cp ${pkgs.noto-fonts-cjk-sans-static}/share/fonts/opentype/noto-cjk/NotoSansCJK-Regular.ttc $out/share/fonts/
  '';
in
{
  home.packages = [ (pkgs.waku.override { fallbackFont = cjkRegular; }) ];
}
