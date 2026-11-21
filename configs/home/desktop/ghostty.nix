{
  programs.ghostty = {
    enable = true;

    # Keep only clipboard and scrollback shortcuts; compositor binds such as
    # `Mod+T` in configs/home/desktop/niri/default.nix still apply.
    clearDefaultKeybinds = true;

    # Colors, font size and background opacity come from stylix
    # (configs/stylix.nix). Ghostty uses the Text face for its regular weight.
    settings = {
      keybind = [
        "ctrl+insert=copy_to_clipboard:mixed"
        "shift+insert=paste_from_selection"
        "ctrl+shift+c=copy_to_clipboard:mixed"
        "ctrl+shift+v=paste_from_clipboard"
        "shift+page_up=scroll_page_up"
        "shift+page_down=scroll_page_down"
        "shift+home=scroll_to_top"
        "shift+end=scroll_to_bottom"
      ];

      mouse-hide-while-typing = true;
      window-padding-x = 10;
      window-padding-y = 10;
      window-padding-balance = "equal";

      # On Linux the default is `linear-corrected`, which dims antialiased
      # pixels and thins 1px CJK strokes relative to kitty's sRGB blending.
      # `native` would match kitty's weight but double-encodes sRGB in the
      # 1.4.0 OpenGL renderer and washes out the background color.
      alpha-blending = "linear";
    };
  };
}
