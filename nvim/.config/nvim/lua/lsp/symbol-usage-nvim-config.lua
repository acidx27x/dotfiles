
vim.pack.add({
  { src = "https://github.com/Wansmer/symbol-usage.nvim" },
})


local kind = vim.lsp.protocol.SymbolKind

require("symbol-usage").setup({
  hl = { link = "NonText" },
  vt_position = "end_of_line",  -- above|end_of_line|textwidth|signcolumn

  -- from lsp SymbolKind https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#symbolKind
  -- kinds = { kind.Function, kind.Method, kind.Class, },
  kinds = {
    kind.Interface, kind.Class, kind.Struct, kind.Enum,
    kind.Constructor, kind.Method, kind.Function,
  },

  references     = { enabled = true, include_declaration = false },
  definition     = { enabled = true, },
  implementation = { enabled = true, },

  request_pending_text = "codelens: loading...",
  text_format = function(symbol)
    local fragments = {}

    -- Indicator that shows if there are any other symbols in the same line
    local stacked_functions = symbol.stacked_count > 0
        and (" | +%s"):format(symbol.stacked_count)
        or ""

    if symbol.references and symbol.references > 0 then
      table.insert(fragments, symbol.references .. " refs")
    end

    if symbol.definition and symbol.definition > 0 then
      table.insert(fragments, symbol.definition .. " defs")
    end

    if symbol.implementation and symbol.implementation > 0 then
      table.insert(fragments, symbol.implementation .. " impls")
    end

    local result = table.concat(fragments, ", ") .. stacked_functions
    if vim.trim(result) ~= "" then
      result = "usage: " .. result
    end

    return result
  end
})

-- disable by default
require("symbol-usage").toggle_globally()
