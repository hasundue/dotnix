{ lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = lib.mkForce {
          family = "PlemolJPConsoleNF";
          style = "Text";
        };
        bold = {
          style = "SemiBold";
        };
        italic = {
          style = "Text Italic";
        };
        bold_italic = {
          style = "SemiBold Italic";
        };
        size = lib.mkForce 13;
      };
      terminal = {
        osc52 = "CopyPaste";
        shell = lib.getExe pkgs.fish;
      };
      window = {
        decorations = "None";
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
      };
    };
  };
}