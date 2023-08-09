{ nix-colors, ... }: 

let
  font = "FiraCode Nerd Font";
  colors = nix-colors.colorSchemes.gruvbox-material-dark-hard.colors;
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        SHELL = "zsh";
      };
      decorations = "none";
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
