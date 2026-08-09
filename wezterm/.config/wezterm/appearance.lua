local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config, platform)
  -- Miasma
  --
  -- Defined locally so the config doesn't depend on it being bundled
  -- by a particular WezTerm version.
  config.color_schemes = {
    Miasma = {
      foreground = '#c2c2b0',
      background = '#222222',

      cursor_bg = '#5f875f',
      cursor_border = '#5f875f',
      cursor_fg = '#222222',

      selection_bg = '#5f875f',
      selection_fg = '#222222',

      ansi = {
        '#222222', -- black
        '#685742', -- red
        '#5f875f', -- green
        '#b36d43', -- yellow
        '#78824b', -- blue
        '#bb7744', -- magenta
        '#c9a554', -- cyan
        '#d7c483', -- white
      },

      brights = {
        '#666666', -- bright black
        '#685742', -- bright red
        '#5f875f', -- bright green
        '#b36d43', -- bright yellow
        '#78824b', -- bright blue
        '#bb7744', -- bright magenta
        '#c9a554', -- bright cyan
        '#d7c483', -- bright white
      },

      tab_bar = {
        background = '#222222',

        active_tab = {
          bg_color = '#5f875f',
          fg_color = '#222222',
          intensity = 'Bold',
        },

        inactive_tab = {
          bg_color = '#222222',
          fg_color = '#c2c2b0',
        },

        inactive_tab_hover = {
          bg_color = '#685742',
          fg_color = '#d7c483',
        },

        new_tab = {
          bg_color = '#222222',
          fg_color = '#666666',
        },

        new_tab_hover = {
          bg_color = '#5f875f',
          fg_color = '#222222',
        },
      },
    },
  }

  config.color_scheme = 'Miasma'

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

  config.window_background_opacity = 0.90

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
  config.use_fancy_tab_bar = false

  config.hide_tab_bar_if_only_one_tab = true

  config.show_tab_index_in_tab_bar = true

  config.show_new_tab_button_in_tab_bar = false

  config.tab_max_width = 32
end

return module
