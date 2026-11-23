{ config, pkgs, ... }:
{
  imports = [ ./worktree-hooks.nix ];

  programs.herdr = {
    enable = true;

    # The TUI writes settings back when they are changed from its UI, so keep
    # the file writable and merge only these keys on activation.
    mutableSettings = true;
    settings = {
      keys.prefix = "ctrl+space";
      theme.name = "kanagawa";
      # Send agent state notifications through the outer terminal.
      ui.toast.delivery = "terminal";
    };
  };

  # A raw store path here would change whenever Herdr is rebuilt, which
  # changes Pi's system prompt and costs a prompt-cache miss. The configured
  # path stays stable while Home Manager updates the symlink target.
  programs.pi-coding-agent.settings.skills = [
    "${config.xdg.dataHome}/herdr/skills/herdr"
  ];
  xdg.dataFile."herdr/skills/herdr".source = "${pkgs.herdr}/share/skills/herdr/herdr";

  # The extension needs its canonical path for `herdr integration status`.
  home.file.".pi/agent/extensions/herdr-agent-state.ts".source =
    "${pkgs.herdr}/share/herdr/integrations/pi/herdr-agent-state.ts";
}
