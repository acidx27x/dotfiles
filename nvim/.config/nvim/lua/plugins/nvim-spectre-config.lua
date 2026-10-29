local lazy = require("plugins.lazy")
local M = {}

function M.setup(rg, sd)
  require("spectre").setup({
    default = {
      find = {
        cmd = rg,
        options = { "ignore-case" },
      },
      replace = {
        cmd = sd,
      },
    },

    is_block_ui_break = true,
  })
end

local function open_spectre(action)
  local tools = require("core.tools")
  local rg = tools.ensure_executable("rg", { "rg" }, "Spectre")
  local sd = tools.ensure_executable("sd", { "sd" }, "Spectre")
  if not rg or not sd then
    return
  end
  lazy.load("spectre", "plugins.nvim-spectre-config", rg, sd)
  require("spectre")[action]()
end

local map = require("core.keymap")
map("n", "<leader>S", function()
  open_spectre("toggle")
end, "search: toggle Spectre")
map("v", "<leader>S", function()
  open_spectre("open_visual")
end, "search: open selection in Spectre")

return M
