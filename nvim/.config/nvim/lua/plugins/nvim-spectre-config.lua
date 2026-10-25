local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  require("spectre").setup({
    default = {
      find = {
        cmd = "rg",
        options = { "ignore-case" },
      },
      replace = {
        cmd = "sd",
      },
    },

    is_block_ui_break = true,
  })
end

lazy.keymap("n", "<leader>S", "spectre", "plugins.nvim-spectre-config", function()
  require("spectre").toggle()
end, "search: toggle Spectre")
lazy.keymap("v", "<leader>S", "spectre", "plugins.nvim-spectre-config", function()
  require("spectre").open_visual()
end, "search: open selection in Spectre")

return M
