{ lib, ... }:
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    extraConfig = lib.mkMerge [
      # Stylix sources tinted-tmux's base16 file, which configures the
      # statusbar only when this variable is in tmux's environment.
      (lib.mkBefore "set-environment -g TINTED_TMUX_OPTION_STATUSBAR 1")
      ''
        set -as terminal-features ",*:RGB"

        set -g extended-keys on
        set -g extended-keys-format csi-u

        unbind C-b
        set -g prefix C-Space
        # Some terminals send Ctrl-Space as NUL instead.
        set -g prefix2 C-@
        bind C-Space send-prefix
      ''
    ];
  };
}
