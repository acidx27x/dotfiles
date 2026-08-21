local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config, platform)
  config.color_scheme = 'duskfox'

  config.font = wezterm.font {
    family = 'Fira Code',
    weight = 'Medium',

    harfbuzz_features = {
      'calt',
      'cv01',
      'cv02',
      'cv06',
      'ss01',
      'cv13',
      'cv14',
      'ss05',
      'ss04',
      'cv18',
      'cv16',
      'cv31',
      'cv29',
      'cv30',
      'cv28',
      'ss06',
      'ss07',
      'ss10',
    },
  }

  config.font_size = 16

  -- Keep this at the font's natural metrics initially.
  config.line_height = 1.0

  config.window_background_opacity = 0.97

  config.window_padding = {
    left = 10,
    right = 10,
    top = 8,
    bottom = 8,
  }

  if platform.is_macos then
    config.macos_window_background_blur = 15
  end

  -- Acrylic-style backdrop on Windows later:
  --
  -- if platform.is_windows then
  --   config.win32_system_backdrop = 'Acrylic'
  -- end

  -- Retro tab bar fits Miasma better than the native/fancy tab bar.
  config.use_fancy_tab_bar = true

  config.hide_tab_bar_if_only_one_tab = true

  config.show_tab_index_in_tab_bar = true

  config.show_new_tab_button_in_tab_bar = false

  config.tab_max_width = 32
end

return module
