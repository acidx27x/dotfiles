
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
require("clangd-config")
--

