
-- lsp plugin group
vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

require("blink-cmp-config")

require("nvim-navic-config")

require("goto-preview-config")

require("symbol-usage-nvim-config")

require("actions-preview-nvim-config")
--


-- lsp server group
require("default-config")

-- c/c++
require("clangd-config")
require("neocmake-config")

-- python
require("ruff-config")
require("ty-config")
--

