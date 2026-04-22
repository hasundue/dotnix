{ ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "kanagawa-themes"
      "lean4"
      "nix"
    ];
    userSettings = {
      agent = {
        thinking_display = "preview";
      };
      agent_buffer_font_size = 14.0;
      agent_servers = {
        github-copilot-cli = {
          type = "registry";
        };
      };
      agent_ui_font_size = 16.0;
      buffer_font_family = "0xProto Nerd Font Mono";
      buffer_font_fallbacks = [ "Noto Sans Mono CJK JP" ];
      buffer_font_size = 14.0;
      buffer_line_height = "comfortable";
      edit_predictions = {
        mode = "subtle";
        provider = "copilot";
      };
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
      ui_font_family = "0xProto Nerd Font Propo";
      ui_font_fallbacks = [ "Noto Sans CJK JP" ];
      ui_font_size = 16.0;
      vim_mode = false;
    };
  };
  stylix.targets.zed.enable = false;
}
