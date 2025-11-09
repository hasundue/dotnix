{ lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        offset = {
          x = 1;
          y = 0;
        };
      };
      terminal = {
        osc52 = "CopyPaste";
        shell = lib.getExe pkgs.fish;
      };
      window = {
        decorations = "None";
        padding = {
          x = 10;
          y = 10;
        };
        dynamic_padding = true;
      };
    };
  };
}
