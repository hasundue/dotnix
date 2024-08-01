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
        size = lib.mkForce 14;
      };
      shell = lib.getExe pkgs.fish;
      terminal = {
        osc52 = "CopyPaste";
      };
      window = {
        decorations = "None";
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
      };
    };
  };
}
