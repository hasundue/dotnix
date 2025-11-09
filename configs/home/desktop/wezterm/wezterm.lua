local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.adjust_window_size_when_changing_font_size = false
config.hide_tab_bar_if_only_one_tab = true

config.font = wezterm.font_with_fallback({
  "0xProto Nerd Font",
  "Noto Sans Mono CJK JP",
  "Noto Color Emoji",
})

config.use_cap_height_to_scale_fallback_fonts = true

return config
