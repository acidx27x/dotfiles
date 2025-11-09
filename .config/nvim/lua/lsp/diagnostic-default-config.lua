
vim.diagnostic.config({
  virtual_lines = false,

  virtual_text = {
    prefix = "▣",
    source = "if_many",
    current_line = nil,  -- show all all lines
  },

  underline        = true,
  severity_sort    = true,
  update_in_insert = false,

  float = {
    prefix    = "",
    source    = "if_many",
    header    = "Diagnostic",
    severity_sort = true,
  },

  signs = {
    severity_sort = true,
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


local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
end

keymap_ns("n", "<C-w>dt", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, "diagnostic: toggle (global)")

-- f is for Focus
keymap_ns("n", "<C-w>dft", function()
  if vim.diagnostic.config().virtual_text.current_line then
    vim.diagnostic.config({ virtual_text = { current_line = nil, }, })
  else
    vim.diagnostic.config({ virtual_text = { current_line = true, }, })
  end
end, "diagnostic: show virtual text for current line (global)")
keymap_ns("n", "<C-w>dfl", function()
  if vim.diagnostic.config().virtual_lines then
    vim.diagnostic.config({ virtual_lines = false, })
  else
    vim.diagnostic.config({ virtual_lines = { current_line = true, }, })
  end
end, "diagnostic: show virtual lines for current line (global)")

keymap_ns("n", "<C-w>dl", vim.diagnostic.setloclist, "diagnostic: setloclist")
keymap_ns("n", "<C-w>do", vim.diagnostic.open_float, "diagnostic: open float")

keymap_ns("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end,  "diagnostic: jump next")
keymap_ns("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "diagnostic: jump prev")

-- restore some remapped combinations
keymap_ns("n", "<C-w>d", "<C-w>d", "")  -- open_float

