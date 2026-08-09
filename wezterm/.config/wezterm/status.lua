local wezterm = require 'wezterm'

local module = {}

function module.register()
  wezterm.on('update-right-status', function(window, pane)
    local parts = {}

    local key_table = window:active_key_table()

    if key_table then
      table.insert(parts, key_table:upper())
    elseif window:leader_is_active() then
      table.insert(parts, 'LEADER')
    end

    -- Shows where this terminal actually lives:
    -- local, WSL:Ubuntu..., SSH:..., or SSHMUX:...
    table.insert(parts, pane:get_domain_name())

    table.insert(parts, window:active_workspace())

    window:set_right_status(
      ' ' .. table.concat(parts, '  |  ') .. ' '
    )
  end)
end

return module
