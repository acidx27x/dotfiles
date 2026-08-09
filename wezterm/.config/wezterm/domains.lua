local wezterm = require 'wezterm'

local module = {}

local function trim(value)
  return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

function module.apply_to_config(config, platform, settings)
  if platform.is_windows then
    local wsl_domains = wezterm.default_wsl_domains()
    local selected_default_domain = nil

    for _, domain in ipairs(wsl_domains) do
      -- Optional friendly alias
      local alias = settings.WSL_ALIASES[domain.distribution]

      if alias then
        domain.name = alias
      end

      -- Default WSL distro
      if settings.DEFAULT_WSL_DISTRO
        and domain.distribution == settings.DEFAULT_WSL_DISTRO
      then
        selected_default_domain = domain.name
      end
    end

    config.wsl_domains = wsl_domains

    if settings.DEFAULT_WSL_DISTRO then
      if selected_default_domain then
        config.default_domain = selected_default_domain
      else
        wezterm.log_warn(
          'DEFAULT_WSL_DISTRO was not found: '
            .. settings.DEFAULT_WSL_DISTRO
        )
      end
    end
  end

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

  config.launch_menu = {}

  local vs_dev_shell_args = nil

  if platform.is_windows then
    table.insert(config.launch_menu, {
      label = 'PowerShell 7',
      domain = {
        DomainName = 'local',
      },
      args = {
        'pwsh.exe',
        '-NoLogo',
      },
    })

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
            'pwsh.exe',
            '-NoLogo',
            '-NoExit',
            '-Command',
            command,
          }

          table.insert(config.launch_menu, {
            label = 'Visual Studio Developer PowerShell 7 — x64',

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

  return {
    vs_dev_shell_args = vs_dev_shell_args,
  }
end

return module
