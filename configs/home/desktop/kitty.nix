{
  programs.kitty = {
    enable = true;
    keybindings = {
      "ctrl+shift+n" = "new_os_window_with_cwd";
    };
    settings = {
      enable_audio_bell = false;
      window_padding_width = 8;
    };
  };
}
