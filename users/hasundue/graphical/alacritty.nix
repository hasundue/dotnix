{ lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
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
