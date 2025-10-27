
vim.pack.add({
  { src = "https://github.com/rmagatti/logger.nvim" },
  { src = "https://github.com/rmagatti/goto-preview" },
})


require("goto-preview").setup {
  width = 120,
  height = 20,

  focus_on_open = true,

  references = {
    provider = "mini_pick",
  },

  vim_ui_input = false,
}

