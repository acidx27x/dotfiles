
-- lsp plugins group
vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

vim.pack.add({
  {
    src     = "https://github.com/Saghen/blink.cmp",
    version = "v1.7.0"  -- need to download binary
  },
})
require("blink-cmp-config")

vim.pack.add({
  { src = "https://github.com/SmiteshP/nvim-navic" },
})
require("nvim-navic-config")
--


-- lsp servers group
require("clangd-config")
--

