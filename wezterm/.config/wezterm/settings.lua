local settings = {}

-- All WSL distributions are discovered automatically.
--
-- Set this to the *distribution* name shown by:
--
--   wsl -l -v
--
-- Example:
--
--   settings.DEFAULT_WSL_DISTRO = 'Ubuntu-24.04'
--
-- Leave nil if you want WezTerm to start in the normal local domain.
settings.DEFAULT_WSL_DISTRO = nil

-- Optional friendly names.
--
-- Keys are the exact distribution names from:
--
--   wsl -l -v
--
-- You DO NOT need to list all your WSL distributions here.
-- This table is only for renaming them.
settings.WSL_ALIASES = {
  -- ['Ubuntu-24.04'] = 'WSL:Ubuntu Dev',
  -- ['Debian'] = 'WSL:Debian',
  -- ['FedoraLinux-42'] = 'WSL:Fedora',
}

return settings
