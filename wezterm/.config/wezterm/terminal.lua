local module = {}

function module.apply_to_config(config, platform, settings)
  -- Keep maximum compatibility with SSH machines.
  -- Don't switch to TERM=wezterm until wezterm terminfo exists everywhere.
  config.term = "xterm-256color"

  config.scrollback_lines = 10000

  config.default_cursor_style = "SteadyBlock"

  config.audible_bell = "Disabled"

  config.hide_mouse_cursor_when_typing = true

  config.adjust_window_size_when_changing_font_size = false

  local platform_name = nil

  if platform.is_macos then
    platform_name = "macos"
  elseif platform.is_linux then
    platform_name = "linux"
  elseif platform.is_windows then
    platform_name = "windows"
  end

  if platform_name and settings.DEFAULT_PROG[platform_name] then
    config.default_prog = settings.DEFAULT_PROG[platform_name]
  elseif platform.is_macos then
    config.default_prog = {
      "/bin/zsh",
      "-l",
    }
  elseif platform.is_linux then
    config.default_prog = {
      "/bin/bash",
      "-l",
    }
  elseif platform.is_windows then
    config.default_prog = {
      "pwsh.exe",
      "-NoLogo",
    }
  end
end

return module
