local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- Platform detection
--------------------------------------------------------------------------------

local is_macos = wezterm.target_triple:find('darwin') ~= nil
local is_windows = wezterm.target_triple:find('windows') ~= nil

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function trim(value)
  return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

--------------------------------------------------------------------------------
-- USER SETTINGS
--------------------------------------------------------------------------------

-- All WSL distributions are discovered automatically.
--
-- Set this to the *distribution* name shown by:
--
--   wsl -l -v
--
-- Example:
--
--   local DEFAULT_WSL_DISTRO = 'Ubuntu-24.04'
--
-- Leave nil if you want WezTerm to start in the normal local domain.
local DEFAULT_WSL_DISTRO = nil

-- Optional friendly names.
--
-- Keys are the exact distribution names from:
--
--   wsl -l -v
--
-- You DO NOT need to list all your WSL distributions here.
-- This table is only for renaming them.
local WSL_ALIASES = {
  -- ['Ubuntu-24.04'] = 'WSL:Ubuntu Dev',
  -- ['Debian'] = 'WSL:Debian',
  -- ['FedoraLinux-42'] = 'WSL:Fedora',
}

--------------------------------------------------------------------------------
-- COLORS
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- FONT
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- TERMINAL
--------------------------------------------------------------------------------

-- Keep maximum compatibility with SSH machines.
-- Don't switch to TERM=wezterm until wezterm terminfo exists everywhere.
config.term = 'xterm-256color'

config.scrollback_lines = 10000

config.default_cursor_style = 'SteadyBlock'

config.audible_bell = 'Disabled'

config.hide_mouse_cursor_when_typing = true

config.adjust_window_size_when_changing_font_size = false

--------------------------------------------------------------------------------
-- WINDOW
--------------------------------------------------------------------------------

config.window_background_opacity = 0.90

config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}

if is_macos then
  config.macos_window_background_blur = 15
end

-- Acrylic-style backdrop on Windows later:
--
-- if is_windows then
--   config.win32_system_backdrop = 'Acrylic'
-- end

--------------------------------------------------------------------------------
-- TAB BAR
--------------------------------------------------------------------------------

-- Retro tab bar fits Miasma better than the native/fancy tab bar.
config.use_fancy_tab_bar = false

config.hide_tab_bar_if_only_one_tab = true

config.show_tab_index_in_tab_bar = true

config.show_new_tab_button_in_tab_bar = false

config.tab_max_width = 32

--------------------------------------------------------------------------------
-- SHELL
--------------------------------------------------------------------------------

-- Eventually recommend:
--
--   chsh -s /opt/homebrew/bin/fish
--
-- and then removing this override.
if is_macos then
  config.default_prog = {
    '/opt/homebrew/bin/bash',
    '-l',
    '-i',
  }
end

--------------------------------------------------------------------------------
-- WSL
--------------------------------------------------------------------------------

if is_windows then
  local wsl_domains = wezterm.default_wsl_domains()
  local selected_default_domain = nil

  for _, domain in ipairs(wsl_domains) do
    ------------------------------------------------------------
    -- Optional friendly alias
    ------------------------------------------------------------

    local alias = WSL_ALIASES[domain.distribution]

    if alias then
      domain.name = alias
    end

    ------------------------------------------------------------
    -- Default WSL distro
    ------------------------------------------------------------

    if DEFAULT_WSL_DISTRO
      and domain.distribution == DEFAULT_WSL_DISTRO
    then
      selected_default_domain = domain.name
    end
  end

  config.wsl_domains = wsl_domains

  if DEFAULT_WSL_DISTRO then
    if selected_default_domain then
      config.default_domain = selected_default_domain
    else
      wezterm.log_warn(
        'DEFAULT_WSL_DISTRO was not found: '
          .. DEFAULT_WSL_DISTRO
      )
    end
  end
end

--------------------------------------------------------------------------------
-- SSH / SSHMUX
--------------------------------------------------------------------------------

-- Reads ~/.ssh/config automatically.
--
-- Every configured host normally gets:
--
--   SSH:hostname
--   SSHMUX:hostname
--
-- SSHMUX requires wezterm on the remote machine.
config.ssh_domains = wezterm.default_ssh_domains()

-- If every regular SSH host you use is Unix/Linux, you may enable this.
-- It improves cwd handling for plain SSH domains.
--
-- for _, domain in ipairs(config.ssh_domains) do
--   if domain.multiplexing == 'None' then
--     domain.assume_shell = 'Posix'
--   end
-- end

-- Example customization for one SSHMUX server:
--
-- for _, domain in ipairs(config.ssh_domains) do
--   if domain.name == 'SSHMUX:devbox' then
--     domain.remote_wezterm_path = '/usr/local/bin/wezterm'
--     domain.local_echo_threshold_ms = 20
--   end
-- end

--------------------------------------------------------------------------------
-- WINDOWS LAUNCH PROFILES
--------------------------------------------------------------------------------

config.launch_menu = {}

local vs_dev_shell_args = nil

if is_windows then
  ------------------------------------------------------------------------------
  -- Normal Windows PowerShell
  ------------------------------------------------------------------------------

  table.insert(config.launch_menu, {
    label = 'Windows PowerShell',
    domain = {
      DomainName = 'local',
    },
    args = {
      'powershell.exe',
      '-NoLogo',
    },
  })

  ------------------------------------------------------------------------------
  -- Visual Studio Developer PowerShell x64
  ------------------------------------------------------------------------------

  local program_files_x86 = os.getenv('ProgramFiles(x86)')

  if program_files_x86 then
    local vswhere =
      program_files_x86
      .. '\\Microsoft Visual Studio\\Installer\\vswhere.exe'

    local success, stdout, stderr =
      wezterm.run_child_process {
        vswhere,
        '-latest',
        '-products',
        '*',
        '-property',
        'installationPath',
      }

    if success then
      local vs_installation = trim(stdout)

      if vs_installation ~= '' then
        local dev_shell_script =
          vs_installation
          .. '\\Common7\\Tools\\Launch-VsDevShell.ps1'

        -- Escape apostrophes for PowerShell single-quoted strings.
        local escaped_script =
          dev_shell_script:gsub("'", "''")

        local command = string.format(
          "& '%s' -Arch amd64 -HostArch amd64 -SkipAutomaticLocation",
          escaped_script
        )

        vs_dev_shell_args = {
          'powershell.exe',
          '-NoLogo',
          '-NoExit',
          '-Command',
          command,
        }

        table.insert(config.launch_menu, {
          label = 'Visual Studio Developer PowerShell — x64',

          domain = {
            DomainName = 'local',
          },

          args = vs_dev_shell_args,
        })
      end
    else
      wezterm.log_warn(
        'vswhere failed: ' .. (stderr or '')
      )
    end
  end
end

--------------------------------------------------------------------------------
-- LEADER
--------------------------------------------------------------------------------

-- macOS:
--   Left Option + S
--
-- Windows:
--   Left Alt + S
--
-- Then release and press the second key.

config.leader = {
  key = 's',
  mods = 'ALT',
  timeout_milliseconds = 1200,
}

--------------------------------------------------------------------------------
-- macOS OPTION BEHAVIOR
--------------------------------------------------------------------------------

if is_macos then
  -- Left Option = terminal Alt
  config.send_composed_key_when_left_alt_is_pressed = false

  -- Right Option = macOS character composition
  config.send_composed_key_when_right_alt_is_pressed = true
end

--------------------------------------------------------------------------------
-- KEY BINDINGS
--------------------------------------------------------------------------------

config.keys = {
  ------------------------------------------------------------------------------
  -- Let shell receive Alt+Left / Alt+Right
  ------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------
  -- Escape hatch for fish Alt+S
  --
  -- Since Alt+S is now the WezTerm leader:
  --
  --   Alt+S, s
  --
  -- sends the original Alt+S to fish.
  ------------------------------------------------------------------------------

  {
    key = 's',
    mods = 'LEADER',

    action = act.SendKey {
      key = 's',
      mods = 'ALT',
    },
  },

  ------------------------------------------------------------------------------
  -- Config
  ------------------------------------------------------------------------------

  {
    key = 'r',
    mods = 'LEADER',
    action = act.ReloadConfiguration,
  },

  ------------------------------------------------------------------------------
  -- Close
  ------------------------------------------------------------------------------

  {
    key = 'x',
    mods = 'LEADER',

    action = act.CloseCurrentPane {
      confirm = true,
    },
  },

  ------------------------------------------------------------------------------
  -- New window in CURRENT domain
  --
  -- Local -> local
  -- WSL   -> same WSL
  -- SSHMUX -> same remote domain
  ------------------------------------------------------------------------------

  {
    key = 'n',
    mods = 'LEADER',

    action = act.SpawnCommandInNewWindow {
      domain = 'CurrentPaneDomain',
    },
  },

  ------------------------------------------------------------------------------
  -- TABS
  ------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------
  -- SPLITS
  ------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------
  -- PANE NAVIGATION
  ------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------
  -- Zoom pane
  ------------------------------------------------------------------------------

  {
    key = 'z',
    mods = 'LEADER',
    action = act.TogglePaneZoomState,
  },

  ------------------------------------------------------------------------------
  -- Pane picker
  ------------------------------------------------------------------------------

  {
    key = 'p',
    mods = 'LEADER',

    action = act.PaneSelect {
      mode = 'Activate',
      show_pane_ids = true,
    },
  },

  ------------------------------------------------------------------------------
  -- Resize mode
  --
  -- Alt+S, e
  --
  -- then:
  --
  --   h j k l
  --
  -- Enter/Escape exits.
  ------------------------------------------------------------------------------

  {
    key = 'e',
    mods = 'LEADER',

    action = act.ActivateKeyTable {
      name = 'resize_pane',
      one_shot = false,
      timeout_milliseconds = 5000,
    },
  },

  ------------------------------------------------------------------------------
  -- Launcher
  --
  -- WSL
  -- SSH
  -- SSHMUX
  -- Windows profiles
  -- workspaces
  ------------------------------------------------------------------------------

  {
    key = 'o',
    mods = 'LEADER',

    action = act.ShowLauncherArgs {
      flags =
        'FUZZY|DOMAINS|LAUNCH_MENU_ITEMS|WORKSPACES',

      title = 'Launch',
    },
  },

  ------------------------------------------------------------------------------
  -- Workspaces
  ------------------------------------------------------------------------------

  {
    key = 'w',
    mods = 'LEADER',

    action = act.ShowLauncherArgs {
      flags = 'FUZZY|WORKSPACES',
      title = 'Workspaces',
    },
  },

  ------------------------------------------------------------------------------
  -- Command palette
  ------------------------------------------------------------------------------

  {
    key = 'p',
    mods = 'LEADER|SHIFT',

    action = act.ActivateCommandPalette,
  },

  ------------------------------------------------------------------------------
  -- Detach current mux domain
  --
  -- Particularly useful with SSHMUX.
  --
  -- Detaching does NOT terminate the remote mux session.
  ------------------------------------------------------------------------------

  {
    key = 'd',
    mods = 'LEADER',

    action = act.DetachDomain 'CurrentPaneDomain',
  },
}

--------------------------------------------------------------------------------
-- QUICK TAB SWITCH: 1-9
--------------------------------------------------------------------------------

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = act.ActivateTab(i - 1),
  })
end

--------------------------------------------------------------------------------
-- VISUAL STUDIO KEY BINDINGS
--------------------------------------------------------------------------------

if vs_dev_shell_args then
  ------------------------------------------------------------------------------
  -- Alt+S, v
  --
  -- New Visual Studio Developer PowerShell x64 TAB
  ------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------
  -- Alt+S, Shift+V
  --
  -- Visual Studio Developer PowerShell x64 SPLIT
  ------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- KEY TABLES
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- MOUSE
--------------------------------------------------------------------------------

-- copy-on-select = clipboard
--
-- This version keeps hyperlink clicking functional as well.

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

--------------------------------------------------------------------------------
-- STATUS BAR
--------------------------------------------------------------------------------

wezterm.on('update-right-status', function(window, pane)
  local parts = {}

  local key_table = window:active_key_table()

  if key_table then
    table.insert(parts, key_table:upper())
  elseif window:leader_is_active() then
    table.insert(parts, 'LEADER')
  end

  --------------------------------------------------------------
  -- Shows where this terminal actually lives:
  --
  -- local
  -- WSL:Ubuntu...
  -- SSH:...
  -- SSHMUX:...
  --------------------------------------------------------------

  table.insert(parts, pane:get_domain_name())

  --------------------------------------------------------------
  -- Workspace
  --------------------------------------------------------------

  table.insert(parts, window:active_workspace())

  window:set_right_status(
    ' ' .. table.concat(parts, '  |  ') .. ' '
  )
end)

--------------------------------------------------------------------------------
-- DONE
--------------------------------------------------------------------------------

return config
