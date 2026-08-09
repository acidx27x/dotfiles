local module = {}

function module.apply_to_config(config, platform)
  -- Keep maximum compatibility with SSH machines.
  -- Don't switch to TERM=wezterm until wezterm terminfo exists everywhere.
  config.term = 'xterm-256color'

  config.scrollback_lines = 10000

  config.default_cursor_style = 'SteadyBlock'

  config.audible_bell = 'Disabled'

  config.hide_mouse_cursor_when_typing = true

  config.adjust_window_size_when_changing_font_size = false

  if platform.is_macos then
    config.default_prog = {
      '/bin/zsh',
      '-l',
    }
  elseif platform.is_linux then
    config.default_prog = {
      '/bin/bash',
      '-l',
    }
  elseif platform.is_windows then
    config.default_prog = {
      'pwsh.exe',
      '-NoLogo',
    }
  end
end

return module
