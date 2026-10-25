local M = {}
local configured = {} -- Config modules register keys at startup; setup runs once on first load.
local map = require("core.keymap")

function M.load(group, module)
  require("plugins.spec").load(group)
  if not configured[module] then
    local config = require(module)
    if type(config) == "table" and config.setup then
      config.setup()
    end
    configured[module] = true
  end
end

function M.keymap(mode, lhs, group, module, action, desc)
  map(mode, lhs, function()
    M.load(group, module)
    action()
  end, desc)
end

return M
