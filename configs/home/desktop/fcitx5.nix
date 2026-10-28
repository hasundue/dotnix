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
        hazkey
        fcitx5-gtk
      ];
      settings = {
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
          "Groups/0/Items/1".Name = "hazkey";
        };
      };
      waylandFrontend = true;
    };
  };

  # Zenzai model for Hazkey. The server looks for it under
  # $XDG_DATA_HOME/hazkey/zenzai/zenzai.gguf.
  xdg.dataFile."hazkey/zenzai/zenzai.gguf".source = "${pkgs.zenzai-model}/share/zenzai.gguf";

  home.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
}
