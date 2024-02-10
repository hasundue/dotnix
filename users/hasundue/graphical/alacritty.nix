{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "None";
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
      };
      terminal = {
        osc52 = "CopyPaste";
      };
    };
  };
}
