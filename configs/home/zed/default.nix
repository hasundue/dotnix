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
        default_profile = "write";
        tool_permissions = {
          tools = {
            delete_path = {
              always_allow = [
              ];
            };
            terminal = {
              always_allow = [
                { pattern = "^nix\\s+develop(\\s|$)"; }
                { pattern = "^git\\s+status(\\s|$)"; }
                { pattern = "^git\\s+add(\\s|$)"; }
                { pattern = "^git\\s+commit(\\s|$)"; }
                { pattern = "^git\\b"; }
                { pattern = "^grep\\b"; }
                { pattern = "^head\\b"; }
                { pattern = "^find\\b"; }
                { pattern = "^sed\\b"; }
                { pattern = "^tail\\b"; }
                { pattern = "^wc\\b"; }
              ];
            };
          };
        };
        thinking_display = "always_collapsed";
      };
      agent_buffer_font_size = 14.0;
      agent_servers = {
        opencode = {
          type = "registry";
        };
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
        provider = "zed";
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
      vim_mode = true;
    };
  };
  stylix.targets.zed.enable = false;
}
