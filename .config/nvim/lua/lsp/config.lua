
-- lsp plugin group
vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

require("blink-cmp-config")

require("nvim-navic-config")

require("goto-preview-config")

require("symbol-usage-nvim-config")
--


-- common diagnostic
vim.diagnostic.config({
  virtual_text = {
    prefix = "▣",
    source = "if_many",
  },
  underline        = true,
  severity_sort    = true,
  update_in_insert = false,
  float = {
    focusable = true,
    style     = "minimal",
    source    = "if_many",
    header    = "",
    prefix    = "",
  },
  signs = {
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticError",
      [vim.diagnostic.severity.WARN]  = "DiagnosticWarn",
      [vim.diagnostic.severity.INFO]  = "DiagnosticInfo",
      [vim.diagnostic.severity.HINT]  = "DiagnosticHint",
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticErrorLn",
      [vim.diagnostic.severity.WARN]  = "DiagnosticWarnLn",
      [vim.diagnostic.severity.INFO]  = "DiagnosticInfoLn",
      [vim.diagnostic.severity.HINT]  = "DiagnosticHintLn",
    },
  },
})
vim.lsp.log.set_level(vim.log.levels.WARN)
--


-- lsp server group

-- c/c++
require("clangd-config")
require("neocmake-config")

-- python
require("ruff-config")
require("ty-config")
--

