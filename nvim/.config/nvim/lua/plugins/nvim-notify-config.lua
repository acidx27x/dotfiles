vim.notify = require("notify")
local map = require("core.keymap")

vim.notify.setup({
  max_width = 80,
  stages = "fade",
  render = "wrapped-default",
})

map({ "n", "v" }, "<leader>nd", vim.notify.dismiss, "nvim-notify: dismiss")
