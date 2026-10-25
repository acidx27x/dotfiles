local wezterm = require("wezterm")

local appearance = require("appearance")
local domains = require("domains")
local keybindings = require("keybindings")
local settings = require("settings")
local status = require("status")
local terminal = require("terminal")

local config = wezterm.config_builder()

config:set_strict_mode(true)

local platform = {
  is_macos = wezterm.target_triple:find("darwin") ~= nil,
  is_linux = wezterm.target_triple:find("linux") ~= nil,
  is_windows = wezterm.target_triple:find("windows") ~= nil,
}

appearance.apply_to_config(config, platform)
terminal.apply_to_config(config, platform, settings)

domains.apply_to_config(config, platform, settings)

keybindings.apply_to_config(config, platform)
status.register()

return config
