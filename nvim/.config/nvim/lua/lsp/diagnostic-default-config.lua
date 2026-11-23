local virtual_text = {
  prefix = "▣",
  source = "if_many",
}

vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = virtual_text,

  underline = true,
  severity_sort = true,
  update_in_insert = false,

  float = function()
    return {
      prefix = "",
      source = "if_many",
      header = "Diagnostic",
      severity_sort = true,
      max_width = math.min(80, math.floor(vim.o.columns * 0.75)),
      max_height = math.min(12, math.floor(vim.o.lines * 0.5)),
    }
  end,

  signs = {
    severity_sort = true,
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticError",
      [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
      [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
      [vim.diagnostic.severity.HINT] = "DiagnosticHint",
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticErrorLn",
      [vim.diagnostic.severity.WARN] = "DiagnosticWarnLn",
      [vim.diagnostic.severity.INFO] = "DiagnosticInfoLn",
      [vim.diagnostic.severity.HINT] = "DiagnosticHintLn",
    },
  },
})

vim.lsp.log.set_level(vim.log.levels.ERROR)

local map = require("core.keymap")

map("n", "<leader>ed", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, "diagnostic: toggle (global)")

map("n", "<leader>et", function()
  local opts = vim.diagnostic.config().virtual_text
  if type(opts) ~= "table" then
    opts = vim.deepcopy(virtual_text)
  end
  opts.current_line = not opts.current_line or nil
  vim.diagnostic.config({ virtual_text = opts, virtual_lines = false })
end, "diagnostic: show virtual text for current line (global)")

map("n", "<leader>el", function()
  if vim.diagnostic.config().virtual_lines then
    vim.diagnostic.config({ virtual_lines = false })
  else
    vim.diagnostic.config({ virtual_text = false, virtual_lines = { current_line = true } })
  end
end, "diagnostic: show virtual lines for current line (global)")

map("n", "<leader>en", function()
  vim.diagnostic.config({ virtual_text = false, virtual_lines = false })
end, "diagnostic: hide virtual text and lines (global)")

map("n", "<leader>ef", vim.diagnostic.open_float, "diagnostic: show current line in float")
map("n", "<leader>eq", vim.diagnostic.setloclist, "diagnostic: setloclist")

for _, item in ipairs({
  { key = "e", severity = vim.diagnostic.severity.ERROR, label = "error" },
  { key = "w", severity = vim.diagnostic.severity.WARN, label = "warning" },
}) do
  map("n", "]" .. item.key, function()
    vim.diagnostic.jump({ count = 1, severity = item.severity })
  end, "diagnostic: jump next " .. item.label)
  map("n", "[" .. item.key, function()
    vim.diagnostic.jump({ count = -1, severity = item.severity })
  end, "diagnostic: jump prev " .. item.label)
end
