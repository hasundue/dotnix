{
  programs.ghostty = {
    enable = true;

    # Colors, font family (0xProto Nerd Font), font size and background
    # opacity all come from stylix (configs/stylix.nix).
    settings = {
      mouse-hide-while-typing = true;
      window-padding-x = 10;
      window-padding-y = 10;

      # 0xProto implements texture healing with `calt`. Ghostty shapes text
      # runs with HarfBuzz, where `calt` is on by default; keep it explicit so
      # the intent survives config churn.
      font-feature = "calt";
    };
  };
}
