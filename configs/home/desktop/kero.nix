{
  pkgs,
  ...
}:

# Only the package: Kero writes its own settings (`~/.config/kero/app.json` and
# `settings.kdl` beside it) from its Settings window, and its terminals take
# their configuration from Ghostty's (`~/.config/ghostty/config`, managed in
# ./ghostty.nix), so there is nothing here to declare.
{
  home.packages = [ pkgs.kero ];
}
