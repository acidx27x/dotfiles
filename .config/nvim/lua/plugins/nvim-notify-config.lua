
vim.pack.add({
  { src = "https://github.com/rcarriga/nvim-notify" },
})


vim.notify = require("notify")


vim.notify.setup({
  max_width = 80,
  stages    = "fade",
  render    = "wrapped-default",
})


vim.keymap.set({ "n", "v" }, "<leader>nd", vim.notify.dismiss,
  { noremap = true, silent = true, desc = "nvim-notify: dismiss", })

