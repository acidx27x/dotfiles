
vim.pack.add({
  { src = "https://github.com/Wansmer/symbol-usage.nvim" },
})


local SymbolKind = vim.lsp.protocol.SymbolKind

require("symbol-usage").setup({
  hl = { link = "NonText" },
  vt_position = "end_of_line",  -- above|end_of_line|textwidth|signcolumn

  -- from lsp.SymbolKind https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#symbolKind
  kinds = { SymbolKind.Function, SymbolKind.Method, SymbolKind.Class, },

  references     = { enabled = true, include_declaration = false },
  definition     = { enabled = true, },
  implementation = { enabled = true, },
})

