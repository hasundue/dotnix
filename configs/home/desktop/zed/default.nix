{ ... }:
{
  imports = [
    ./language-models.nix
  ];

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
        favorite_models = [
          {
            provider = "OpenCode Go";
            model = "deepseek-v4-flash";
            enable_thinking = true;
          }
          {
            provider = "OpenCode Go";
            model = "deepseek-v4-pro";
            enable_thinking = true;
          }
          {
            provider = "OpenCode Go";
            model = "kimi-k2.6";
            enable_thinking = true;
          }
        ];
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
        default_model = {
          provider = "OpenCode Go";
          model = "minimax-m2.7";
          enable_thinking = false;
        };
        thinking_display = "always_collapsed";
      };
      agent_buffer_font_size = 14.0;
      agent_servers = {
        github-copilot-cli = {
          type = "registry";
        };
      };
      agent_ui_font_size = 16.0;
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
      semantic_tokens = "combined";
      vim_mode = true;
    };
  };
}
