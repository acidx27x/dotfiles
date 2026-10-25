local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  require("no-neck-pain").setup({
    width = 120,
    buffers = {
      scratchPad = {
        enabled = true,
        fileName = "scratch-notes",
        location = nil, -- or full path
      },
      bo = {
        filetype = "md",
        fillchars = "eob: ",
      },
    },
  })
end

lazy.keymap("n", "<leader>np", "no_neck_pain", "plugins.no-neck-pain-nvim-config", function()
  vim.cmd.NoNeckPain()
end, "layout: toggle centered buffer")

return M
