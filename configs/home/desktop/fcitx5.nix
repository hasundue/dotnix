{ pkgs, ... }:

{
  gtk = {
    gtk2.extraConfig = ''
      gtk-im-module="fcitx"
    '';
    gtk3.extraConfig = {
      gtk-im-module = "fcitx";
    };
    gtk4.extraConfig = {
      gtk-im-module = "fcitx";
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
      settings = {
        globalOptions = {
          Hotkey.EnumerateGroupForwardKeys = "";
          "Hotkey/TriggerKeys"."0" = "Super+space";
          # Kanata emits F13 (seen as Tools) before the tmux/Herdr prefix.
          # Shift is in both lists: while active it toggles Mozc off through
          # AltTriggerKeys, and while inactive ActivateKeys turns it back on
          # even when Tools performed the deactivation.
          Hotkey.ConsumeRedundantActivateKeys = true;
          "Hotkey/DeactivateKeys"."0" = "Tools";
          "Hotkey/ActivateKeys"."0" = "Shift_L";
          "Hotkey/AltTriggerKeys"."0" = "Shift_L";
        };
        addons = {
          clipboard.globalSection.TriggerKey = ""; # Ctrl+; to disable
        };
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "mozc";
        };
      };
      waylandFrontend = true;
    };
  };

  home.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
}
