
vim.pack.add({
  { src = "https://github.com/m4xshen/smartcolumn.nvim" },
})


require("smartcolumn").setup({
  colorcolumn  = "120",  -- use max_line_length from EditorConfig
  editorconfig = true,
  disabled_filetypes = {
    "help", "text", "markdown",
    "neo-tree", "checkhealth",
    "lspinfo", "noice",
  },
})

