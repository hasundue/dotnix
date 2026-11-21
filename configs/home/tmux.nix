{ lib, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    extraConfig = lib.mkMerge [
      # Stylix sources tinted-tmux's base16 file, which configures the
      # statusbar only when this variable is in tmux's environment.
      (lib.mkBefore "set-environment -g TINTED_TMUX_OPTION_STATUSBAR 1")
      ''
        set -as terminal-features ",*:RGB"
        set -g extended-keys on
        set -g extended-keys-format csi-u
      ''
    ];
    focusEvents = true;
    keyMode = "vi";
    mouse = true;
    shortcut = "Space";
    terminal = "tmux-256color";
  };
}
