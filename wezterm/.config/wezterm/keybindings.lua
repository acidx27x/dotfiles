local wezterm = require 'wezterm'
local act = wezterm.action

local module = {}

function module.apply_to_config(config, platform, domain_context)
  -- macOS: Left Option + S
  -- Windows: Left Alt + S
  -- Then release and press the second key.
  config.leader = {
    key = 's',
    mods = 'ALT',
    timeout_milliseconds = 1200,
  }

  if platform.is_macos then
    -- Left Option = terminal Alt
    config.send_composed_key_when_left_alt_is_pressed = false

    -- Right Option = macOS character composition
    config.send_composed_key_when_right_alt_is_pressed = true
  end

  config.keys = {
    -- Let shell receive Alt+Left / Alt+Right.
    {
      key = 'LeftArrow',
      mods = 'ALT',
      action = act.DisableDefaultAssignment,
    },

    {
      key = 'RightArrow',
      mods = 'ALT',
      action = act.DisableDefaultAssignment,
    },

    -- Escape hatch for shell Alt+S. Since Alt+S is the WezTerm leader,
    -- Alt+S, s sends the original Alt+S to the shell.
    {
      key = 's',
      mods = 'LEADER',

      action = act.SendKey {
        key = 's',
        mods = 'ALT',
      },
    },

    {
      key = 'r',
      mods = 'LEADER',
      action = act.ReloadConfiguration,
    },

    {
      key = 'x',
      mods = 'LEADER',

      action = act.CloseCurrentPane {
        confirm = true,
      },
    },

    -- New window in the current domain:
    -- local -> local, WSL -> same WSL, SSHMUX -> same remote domain.
    {
      key = 'n',
      mods = 'LEADER',

      action = act.SpawnCommandInNewWindow {
        domain = 'CurrentPaneDomain',
      },
    },

    {
      key = 'c',
      mods = 'LEADER',

      action = act.SpawnTab 'CurrentPaneDomain',
    },

    {
      key = 'h',
      mods = 'LEADER|SHIFT',

      action = act.ActivateTabRelative(-1),
    },

    {
      key = 'l',
      mods = 'LEADER|SHIFT',

      action = act.ActivateTabRelative(1),
    },

    {
      key = ',',
      mods = 'LEADER',

      action = act.MoveTabRelative(-1),
    },

    {
      key = '.',
      mods = 'LEADER',

      action = act.MoveTabRelative(1),
    },

    {
      key = '\\',
      mods = 'LEADER',

      action = act.SplitPane {
        direction = 'Right',
        size = {
          Percent = 50,
        },

        command = {
          domain = 'CurrentPaneDomain',
        },
      },
    },

    {
      key = '-',
      mods = 'LEADER',

      action = act.SplitPane {
        direction = 'Down',
        size = {
          Percent = 50,
        },

        command = {
          domain = 'CurrentPaneDomain',
        },
      },
    },

    {
      key = 'h',
      mods = 'LEADER',
      action = act.ActivatePaneDirection 'Left',
    },

    {
      key = 'j',
      mods = 'LEADER',
      action = act.ActivatePaneDirection 'Down',
    },

    {
      key = 'k',
      mods = 'LEADER',
      action = act.ActivatePaneDirection 'Up',
    },

    {
      key = 'l',
      mods = 'LEADER',
      action = act.ActivatePaneDirection 'Right',
    },

    {
      key = 'z',
      mods = 'LEADER',
      action = act.TogglePaneZoomState,
    },

    {
      key = 'p',
      mods = 'LEADER',

      action = act.PaneSelect {
        mode = 'Activate',
        show_pane_ids = true,
      },
    },

    -- Alt+S, e enters resize mode. h/j/k/l resize; Enter/Escape exits.
    {
      key = 'e',
      mods = 'LEADER',

      action = act.ActivateKeyTable {
        name = 'resize_pane',
        one_shot = false,
        timeout_milliseconds = 5000,
      },
    },

    -- WSL, SSH, SSHMUX, Windows profiles, and workspaces.
    {
      key = 'o',
      mods = 'LEADER',

      action = act.ShowLauncherArgs {
        flags =
          'FUZZY|DOMAINS|LAUNCH_MENU_ITEMS|WORKSPACES',

        title = 'Launch',
      },
    },

    {
      key = 'w',
      mods = 'LEADER',

      action = act.ShowLauncherArgs {
        flags = 'FUZZY|WORKSPACES',
        title = 'Workspaces',
      },
    },

    {
      key = 'p',
      mods = 'LEADER|SHIFT',

      action = act.ActivateCommandPalette,
    },

    -- Particularly useful with SSHMUX. Detaching does not terminate the
    -- remote mux session.
    {
      key = 'd',
      mods = 'LEADER',

      action = act.DetachDomain 'CurrentPaneDomain',
    },
  }

  -- Quick tab switch: 1-9.
  for i = 1, 9 do
    table.insert(config.keys, {
      key = tostring(i),
      mods = 'LEADER',
      action = act.ActivateTab(i - 1),
    })
  end

  local vs_dev_shell_args = domain_context.vs_dev_shell_args

  if vs_dev_shell_args then
    -- Alt+S, v: new Visual Studio Developer PowerShell 7 x64 tab.
    table.insert(config.keys, {
      key = 'v',
      mods = 'LEADER',

      action = act.SpawnCommandInNewTab {
        domain = {
          DomainName = 'local',
        },

        args = vs_dev_shell_args,
      },
    })

    -- Alt+S, Shift+V: Visual Studio Developer PowerShell 7 x64 split.
    table.insert(config.keys, {
      key = 'v',
      mods = 'LEADER|SHIFT',

      action = act.SplitPane {
        direction = 'Right',

        size = {
          Percent = 50,
        },

        command = {
          domain = {
            DomainName = 'local',
          },

          args = vs_dev_shell_args,
        },
      },
    })
  end

  config.key_tables = {
    resize_pane = {
      {
        key = 'h',
        mods = 'NONE',

        action = act.AdjustPaneSize {
          'Left',
          3,
        },
      },

      {
        key = 'j',
        mods = 'NONE',

        action = act.AdjustPaneSize {
          'Down',
          3,
        },
      },

      {
        key = 'k',
        mods = 'NONE',

        action = act.AdjustPaneSize {
          'Up',
          3,
        },
      },

      {
        key = 'l',
        mods = 'NONE',

        action = act.AdjustPaneSize {
          'Right',
          3,
        },
      },

      {
        key = 'Enter',
        mods = 'NONE',
        action = act.PopKeyTable,
      },

      {
        key = 'Escape',
        mods = 'NONE',
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
          button = 'Left',
        },
      },

      mods = 'NONE',

      action =
        act.CompleteSelectionOrOpenLinkAtMouseCursor 'Clipboard',
    },
  }
end

return module
