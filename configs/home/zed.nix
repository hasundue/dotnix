{ config, ... }:
let
  font_fallbacks = [ "Noto Sans Mono CJK JP" ];
in
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "kanagawa-themes"
      "nix"
    ];
    userSettings = {
      features = {
        edit_prediction_provider = "copilot";
      };
      buffer_font_fallbacks = font_fallbacks;
      buffer_font_size = 15;
      buffer_line_height."custom" = 1.618;
      languages = {
        Nix = {
          language_servers = [
            "nil"
            "!nixd"
          ];
        };
      };
      load_direnv = "shell_hook";
      theme = "Kanagawa Wave - No Italics";
      ui_font_family = config.stylix.fonts.monospace.name;
      ui_font_size = 16;
      ui_font_fallbacks = font_fallbacks;
      vim_mode = true;
    };
  };
  stylix.targets.zed.enable = false;
}
