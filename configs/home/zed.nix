{ config, lib, ... }:
let
  font_fallbacks = [ "Noto Sans Mono CJK JP" ];
in
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "kanagawa-themes" ];
    userSettings = {
      buffer_font_fallbacks = font_fallbacks;
      buffer_font_size = lib.mkForce 15;
      buffer_line_height."custom" = 1.618;
      theme = lib.mkForce "Kanagawa Wave - No Italics";
      ui_font_fallbacks = font_fallbacks;
      ui_font_family = lib.mkForce config.stylix.fonts.monospace.name;
      ui_font_size = lib.mkForce 16;
    };
  };
}
