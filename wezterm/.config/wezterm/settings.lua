local settings = {}

-- These settings can be overwrited by 'local_settings.lua'
settings.DEFAULT_WSL_DISTRO = nil
settings.WSL_ALIASES = {}
settings.UNIX_HOSTS = {}
settings.DEFAULT_PROG = {}
settings.SSH_DOMAIN_OVERRIDES = {}

local local_settings_path = package.searchpath("local_settings", package.path)

if local_settings_path then
  local local_settings = require("local_settings")

  if local_settings.DEFAULT_WSL_DISTRO ~= nil then
    settings.DEFAULT_WSL_DISTRO = local_settings.DEFAULT_WSL_DISTRO
  end

  for distro, alias in pairs(local_settings.WSL_ALIASES or {}) do
    settings.WSL_ALIASES[distro] = alias
  end

  if local_settings.UNIX_HOSTS then
    settings.UNIX_HOSTS = local_settings.UNIX_HOSTS
  end

  for platform, program in pairs(local_settings.DEFAULT_PROG or {}) do
    settings.DEFAULT_PROG[platform] = program
  end

  for domain, overrides in pairs(local_settings.SSH_DOMAIN_OVERRIDES or {}) do
    settings.SSH_DOMAIN_OVERRIDES[domain] = overrides
  end
end

return settings
