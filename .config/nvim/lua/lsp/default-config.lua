
-- default config
vim.lsp.config('*', {
  root_markers = { '.git' },

  single_file_support = true,

  flags = {
    debounce_text_changes  = 150,
    allow_incremental_sync = true,
  },
})


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
vim.lsp.log.set_level(vim.log.levels.ERROR)

