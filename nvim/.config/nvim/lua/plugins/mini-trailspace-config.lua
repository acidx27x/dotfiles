require("mini.trailspace").setup({
  only_in_normal_buffers = true,
})

local map = require("core.keymap")

map("n", "<leader>tw", function()
  MiniTrailspace.trim()
  MiniTrailspace.trim_last_lines()
end, "whitespace: trim trailing spaces and lines")
