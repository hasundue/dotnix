{ nix-colors, ... }: 

let
  font = "FiraCode Nerd Font";
  colors = nix-colors.colorSchemes.nord.colors;
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        SHELL = "zsh";
      };
      decorations = "none";
      opacity = 0.9;
      font = {
        normal = { family = font; style = "Regular"; };
        bold = { family = font; style = "Bold"; };
        italic = { family = font; style = "Oblique"; };
        size = 10.0;
      };
      colors = {
        background = "#${colors.base00}";
        foreground = "#${colors.base04}";
      };
      window = {
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
      };
    };
  };
}
