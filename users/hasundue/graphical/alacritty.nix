{
  programs.alacritty = {
    enable = true;
    settings = {
      decorations = "none";
      font = {
        offset = { x = 1; y = 1; };
      };
      window = {
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
      };
    };
  };
}
