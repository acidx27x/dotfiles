local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

function module.apply_to_config(config, platform)
  local modifier = platform.is_macos and "SUPER" or "CTRL|SHIFT"

  if platform.is_macos then
    -- Left Option = terminal Alt
    config.send_composed_key_when_left_alt_is_pressed = false

    -- Right Option = macOS character composition
    config.send_composed_key_when_right_alt_is_pressed = true
  end

  config.keys = {
    -- Close only the focused pane; the default closes the whole tab.
    {
      key = "w",
      mods = modifier,
      action = act.CloseCurrentPane({
        confirm = true,
      }),
    },
    {
      key = "|",
      mods = modifier,
      action = act.SplitPane({
        direction = "Right",
        size = {
          Percent = 50,
        },
        command = {
          domain = "CurrentPaneDomain",
        },
      }),
    },
    {
      key = "?",
      mods = modifier,
      action = act.SplitPane({
        direction = "Down",
        size = {
          Percent = 50,
        },
        command = {
          domain = "CurrentPaneDomain",
        },
      }),
    },
    {
      key = "a",
      mods = modifier,
      action = act.PaneSelect({
        mode = "Activate",
        show_pane_ids = true,
      }),
    },
    {
      key = "e",
      mods = modifier,
      action = act.ActivateKeyTable({
        name = "resize_pane",
        one_shot = false,
        timeout_milliseconds = 5000,
      }),
    },
    {
      key = "o",
      mods = modifier,
      action = act.ShowLauncherArgs({
        flags = "FUZZY|DOMAINS|LAUNCH_MENU_ITEMS|WORKSPACES",

        title = "Launch",
      }),
    },
    {
      key = "n",
      mods = modifier .. "|ALT",
      action = act.SpawnCommandInNewWindow({
        domain = "CurrentPaneDomain",
      }),
    },
    {
      key = "d",
      mods = modifier,
      action = act.DetachDomain("CurrentPaneDomain"),
    },
  }

  config.key_tables = {
    resize_pane = {
      {
        key = "h",
        mods = "NONE",
        action = act.AdjustPaneSize({
          "Left",
          3,
        }),
      },
      {
        key = "j",
        mods = "NONE",
        action = act.AdjustPaneSize({
          "Down",
          3,
        }),
      },
      {
        key = "k",
        mods = "NONE",
        action = act.AdjustPaneSize({
          "Up",
          3,
        }),
      },
      {
        key = "l",
        mods = "NONE",
        action = act.AdjustPaneSize({
          "Right",
          3,
        }),
      },

      {
        key = "Enter",
        mods = "NONE",
        action = act.PopKeyTable,
      },
      {
        key = "Escape",
        mods = "NONE",
        action = act.PopKeyTable,
      },
    },
  }

  -- copy-on-select = clipboard; hyperlink clicking remains functional.
  config.mouse_bindings = {
    {
      event = {
        Up = {
          streak = 1,
          button = "Left",
        },
      },
      mods = "NONE",
      action = act.CompleteSelectionOrOpenLinkAtMouseCursor("Clipboard"),
    },
  }
end

return module
