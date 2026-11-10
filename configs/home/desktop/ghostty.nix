{
  lib,
  ...
}:
{
  programs.ghostty = {
    enable = true;

    # No Ghostty-level shortcuts (`keybind = clear`); compositor binds such as
    # `Mod+T` in configs/home/desktop/niri/default.nix still apply.
    clearDefaultKeybinds = true;

    # Colors, font family (0xProto Nerd Font), font size and background
    # opacity all come from stylix (configs/stylix.nix).
    settings = {
      mouse-hide-while-typing = true;
      window-padding-x = 10;
      window-padding-y = 10;
      window-padding-balance = "equal";

      # 0xProto implements texture healing with `calt`. Ghostty shapes text
      # runs with HarfBuzz, where `calt` is on by default; keep it explicit so
      # the intent survives config churn.
      font-feature = "calt";

      # On Linux the default is `linear-corrected`, which dims antialiased
      # pixels and thins 1px CJK strokes relative to kitty's sRGB blending.
      # `native` would match kitty's weight but double-encodes sRGB in the
      # 1.4.0 OpenGL renderer and washes out the background color.
      alpha-blending = "linear";

      # Auto-discovered fallbacks are scaled to the primary font's ideograph
      # width (0.982em for 0xProto), so the CJK face lands smaller than the
      # nominal size. An explicit family keeps it at the nominal size, which
      # is what kitty does.
      font-family = lib.mkAfter [ "Noto Sans Mono CJK JP" ];
    };
  };
}
