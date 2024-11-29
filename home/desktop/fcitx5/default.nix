{ pkgs, ... }:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
  };

  home.sessionVariables = {
    GLFW_IM_MODULE = "ibus";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  xdg.configFile = {
    "fcitx5/conf/classicui.conf".source = ./classicui.conf;
  };

  xdg.dataFile = {
    "fcitx5/themes/default/theme.conf".source = ./theme.conf;
  };
}
