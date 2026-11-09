{ pkgs, ... }:
let
  # GPUI draws every glyph with empty font variations, so a variable font comes
  # out in its default instance. nixpkgs' Noto Sans CJK VF defaults to
  # wght=100 (Thin), which makes Japanese text hairline thin, while
  # fontconfig-based applications get the named instances they ask for.
  #
  # cosmic-text's fallback only keeps a static face whose weight is an exact
  # match (`font_weight_diff == 0`) or a variable face whose axis covers the
  # request. So one static face is not enough: Waku asks for 400 (body), 500
  # (medium labels), 600 (headings and emphasis) and 700 (h1/h2). The static
  # release has no SemiBold face, so relabel its Bold faces as 600; the
  # outlines stay bold, the conventional fallback for semibold.
  cjkFallback =
    pkgs.runCommandLocal "waku-cjk-fallback"
      {
        nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.fonttools ])) ];
      }
      ''
        mkdir -p $out/share/fonts
        cp ${pkgs.noto-fonts-cjk-sans-static}/share/fonts/opentype/noto-cjk/NotoSansCJK-{Regular,Medium,Bold}.ttc $out/share/fonts/

        OUT=$out/share/fonts/NotoSansCJK-SemiBold.ttc python3 - <<'PY'
        import os
        from fontTools.ttLib import TTCollection

        collection = TTCollection(
            "${pkgs.noto-fonts-cjk-sans-static}/share/fonts/opentype/noto-cjk/NotoSansCJK-Bold.ttc"
        )
        for face in collection.fonts:
            face["OS/2"].usWeightClass = 600
        collection.save(os.environ["OUT"])
        PY
      '';
in
{
  home.packages = [ (pkgs.waku.override { fallbackFont = cjkFallback; }) ];
}
