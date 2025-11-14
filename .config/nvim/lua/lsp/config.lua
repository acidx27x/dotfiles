
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
require("lsp-default-config")
require("diagnostic-default-config")

-- c/c++
require("clangd-config")
require("neocmake-config")

-- python
require("basedpyright-config")
require("ruff-config")
require("ty-config")
--

