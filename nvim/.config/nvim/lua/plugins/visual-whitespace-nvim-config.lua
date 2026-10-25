local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  require("visual-whitespace").setup({
    match_types = {
      space = true,
      tab = true,
      nbsp = true,
      lead = true,
      trail = true,
    },
    list_chars = {
      space = "·",
      lead = "·",
      trail = "·",
    },
  })
end

lazy.keymap({ "n", "v" }, "<leader>vw", "buffer_ui", "plugins.visual-whitespace-nvim-config", function()
  require("visual-whitespace").toggle()
end, "Toggle Visual Whitespace Viewer")

return M
