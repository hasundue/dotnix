{
  config,
  pkgs,
  ...
}:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
in
{
  pi = {
    enable = true;
    packagesDir = ./.;

    packages = {
      pi-mcporter.settings = {
        mode = "lazy";
        timeoutMs = 30000;
      };

      "@juicesharp/rpiv-pi".enable = false;
    };

    settings = {
      theme = "kanagawa-wave";
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "high";
      hideThinkingBlock = true;
      enabledModels = [
        "opencode-go/deepseek-v4-flash"
        "opencode-go/deepseek-v4-pro"
      ];
    };

    auth = {
      opencode-go = {
        type = "api_key";
        key = "!cat ${opencodeGoKeyPath}";
      };
    };

    themes = [
      ./themes/kanagawa-wave.json
    ];

    extensions = [
      ./extensions/chat-display.ts
      # ./extensions/footer.ts
      # ./extensions/readonly-mode
      # ./extensions/toggle-bash
    ];

    skills = [
      "${pkgs.worktrunk.src}/skills/worktrunk"
      # ./skills/exa-search
    ];

    keybindings = {
      "app.session.rename" = "ctrl+shift+r";
    };
  };

  programs.git.ignores = [
    ".pi/"
    ".rpiv/"
  ];

}
