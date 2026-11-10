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

  local bindings = {
    -- Close only the focused pane; the default closes the whole tab.
    {
      brief = "User | Pane: Close",
      key = "w",
      mods = modifier,
      action = act.CloseCurrentPane({
        confirm = true,
      }),
    },
    {
      brief = "User | Pane: Split right",
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
      brief = "User | Pane: Split down",
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
      brief = "User | Pane: Select",
      key = "q",
      mods = "CTRL|SHIFT",
      action = act.PaneSelect({
        mode = "Activate",
        show_pane_ids = true,
      }),
    },
    {
      brief = "User | Pane: Resize mode",
      key = "e",
      mods = modifier,
      action = act.ActivateKeyTable({
        name = "resize_pane",
        one_shot = false,
        timeout_milliseconds = 5000,
      }),
    },
    {
      brief = "User | Window: Launcher",
      key = "o",
      mods = modifier,
      action = act.ShowLauncherArgs({
        flags = "FUZZY|DOMAINS|LAUNCH_MENU_ITEMS|WORKSPACES",

        title = "Launch",
      }),
    },
    {
      brief = "User | Window: New window in current domain",
      key = "n",
      mods = modifier .. "|ALT",
      action = act.SpawnCommandInNewWindow({
        domain = "CurrentPaneDomain",
      }),
    },
    {
      brief = "User | Workspace: Detach current domain",
      key = "d",
      mods = modifier,
      action = act.DetachDomain("CurrentPaneDomain"),
    },
    {
      brief = "User | Workspace: Switch",
      key = "s",
      mods = modifier,
      action = act.ShowLauncherArgs({
        flags = "FUZZY|WORKSPACES",
        title = "Workspaces",
      }),
    },
    {
      brief = "User | Workspace: Create or switch by name",
      key = "s",
      mods = modifier .. "|ALT",
      action = act.PromptInputLine({
        description = "Workspace name",
        action = wezterm.action_callback(function(window, pane, line)
          if line and line ~= "" then
            window:perform_action(act.SwitchToWorkspace({
              name = line,
            }), pane)
          end
        end),
      }),
    },
    {
      brief = "User | Tab: New tab",
      key = "t",
      mods = modifier,
      action = act.SpawnTab("CurrentPaneDomain"),
    },
    {
      brief = "User | Window: New window",
      key = "n",
      mods = modifier,
      action = act.SpawnWindow,
    },
    {
      brief = "User | Edit: Copy",
      key = "c",
      mods = modifier,
      action = act.CopyTo("Clipboard"),
    },
    {
      brief = "User | Edit: Paste",
      key = "v",
      mods = modifier,
      action = act.PasteFrom("Clipboard"),
    },
    {
      brief = "User | Edit: Search",
      key = "f",
      mods = modifier,
      action = act.Search("CurrentSelectionOrEmptyString"),
    },
    {
      brief = "User | Window: Command palette",
      key = "p",
      mods = "CTRL|SHIFT",
      action = act.ActivateCommandPalette,
    },
    {
      brief = "User | Pane: Toggle zoom",
      key = "z",
      mods = "CTRL|SHIFT",
      action = act.TogglePaneZoomState,
    },
  }

  for _, direction in ipairs({
    {
      key = "h",
      arrow = "LeftArrow",
      name = "Left",
    },
    {
      key = "j",
      arrow = "DownArrow",
      name = "Down",
    },
    {
      key = "k",
      arrow = "UpArrow",
      name = "Up",
    },
    {
      key = "l",
      arrow = "RightArrow",
      name = "Right",
    },
  }) do
    table.insert(bindings, {
      brief = "User | Pane: Focus " .. direction.name:lower(),
      key = direction.key,
      mods = "CTRL|SHIFT",
      action = act.ActivatePaneDirection(direction.name),
    })
    table.insert(bindings, {
      brief = "User | Pane: Focus " .. direction.name:lower(),
      key = direction.arrow,
      mods = "CTRL|SHIFT",
      action = act.ActivatePaneDirection(direction.name),
    })
    table.insert(bindings, {
      brief = "User | Pane: Resize " .. direction.name:lower(),
      key = direction.arrow,
      mods = "CTRL|SHIFT|ALT",
      action = act.AdjustPaneSize({
        direction.name,
        1,
      }),
    })
  end

  config.keys = {}
  local palette = {}
  local palette_names = {}
  for _, binding in ipairs(bindings) do
    table.insert(config.keys, {
      key = binding.key,
      mods = binding.mods,
      action = binding.action,
    })
    if not palette_names[binding.brief] then
      table.insert(palette, {
        brief = binding.brief,
        action = binding.action,
      })
      palette_names[binding.brief] = true
    end
  end
  wezterm.on("augment-command-palette", function()
    return palette
  end)

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
