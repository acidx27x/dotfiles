
local M = {}


M.lsp_keymaps = function(bufnr)
  local function getopts(desc)
    return { noremap = true, silent = true, buffer = bufnr, desc = desc }
  end
  local function keyn(key, func, opts)
    vim.keymap.set("n", key, func, opts)
  end

  keyn("gd", vim.lsp.buf.definition,      getopts("LSP: definition (buf)"))
  keyn("gy", vim.lsp.buf.type_definition, getopts("LSP: type_definition (buf)"))
  keyn("gc", vim.lsp.buf.declaration,     getopts("LSP: declaration (buf)"))
  keyn("gr", vim.lsp.buf.references,      getopts("LSP: references (buf)"))
  keyn("gi", vim.lsp.buf.implementation,  getopts("LSP: implementation (buf)"))
  keyn("gs", vim.lsp.buf.document_symbol, getopts("LSP: document_symbol (buf)"))

  -- C-s because lSp
  keyn("<C-s>h", vim.lsp.buf.hover,          getopts("LSP: hover (buf)"))
  keyn("<C-s>s", vim.lsp.buf.signature_help, getopts("LSP: signature_help (buf)"))

  keyn("<C-s>rn", vim.lsp.buf.rename,      getopts("LSP: rename (buf)"))
  keyn("<C-s>ca", vim.lsp.buf.code_action, getopts("LSP: code_action (buf)"))

  keyn("<C-w>dl", vim.diagnostic.setloclist, getopts("diagnostic: setloclist"))
  keyn("<C-w>do", vim.diagnostic.open_float, getopts("diagnostic: open_float"))
  keyn("]d", function()
    vim.diagnostic.jump({ count = 1 })
  end,  getopts("diagnostic: jump next"))
  keyn("[d", function()
    vim.diagnostic.jump({ count = -1 })
  end, getopts("diagnostic: jump prev"))

  keyn("<C-s>i", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
  end, getopts("LSP: toggle inlay_hint"))
  keyn("<C-s>I", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, getopts("LSP: toggle inlay_hint (buf)"))

  keyn("<C-s>dh", vim.lsp.buf.document_highlight, getopts("LSP: document_highlight"))
  keyn("<C-s>cr", vim.lsp.buf.clear_references,   getopts("LSP: clear_references"))

  -- restore some remapped combinations
  keyn("K",   "K",   getopts(""))  -- hover
  keyn("gri", "gri", getopts(""))  -- implementation
  keyn("grn", "grn", getopts(""))  -- rename
  keyn("grr", "grr", getopts(""))  -- references
  keyn("grt", "grt", getopts(""))  -- type_definition
  keyn("gO",  "gO",  getopts(""))  -- document_symbol
  keyn("<C-w>d", "<C-w>d", getopts(""))  -- open_float

  vim.keymap.set({ "n", "v" }, "gra", "gra", getopts(""))  -- code_action
  vim.keymap.set("i", "<C-s>", "<C-s>", getopts(""))  -- signature_help
end


M.get_capabilities = function(server_name)
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- shared override capabilities
  capabilities.textDocument.completion.completionItem = {
    snippetSupport = false,
  }

  capabilities.textDocument.formatting = {
    dynamicRegistration = false,
  }
  capabilities.textDocument.rangeFormatting = {
    rangesSupport       = false,
    dynamicRegistration = false,
  }
  --

  return require("blink.cmp").get_lsp_capabilities(capabilities)
end


M.on_attach = function(client, bufnr)
  M.lsp_keymaps(bufnr)

  -- shared override capabilities
  vim.bo[bufnr].formatexpr = nil
  client.server_capabilities.documentFormattingProvider       = false
  client.server_capabilities.documentRangeFormattingProvider  = false
  client.server_capabilities.documentOnTypeFormattingProvider = false
  --

  if client.server_capabilities.foldingRangeProvider then
    vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
  end

  if client.server_capabilities.documentSymbolProvider then
    require("nvim-navic").attach(client, bufnr)
  end

  if client.server_capabilities.semanticTokensProvider then
    vim.treesitter.stop(bufnr)
  end

  if client.server_capabilities.completionProvider then
    vim.bo[bufnr].omnifunc = nil
  end

  -- i use swap files, buf swap uses update time builtin option, so cant set it to very low time
  -- if client.server_capabilities.documentHighlightProvider then
  --  local group = vim.api.nvim_create_augroup("LspHighlightCursorSymbol", {clear = false})

  --  vim.api.nvim_clear_autocmds({buffer = bufnr, group = group})

  --  vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
  --    group    = group,
  --    buffer   = bufnr,
  --    callback = vim.lsp.buf.document_highlight,
  --    desc = "Highlight References Under Cursor"
  --  })

  --  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
  --    group    = group,
  --    buffer   = bufnr,
  --    callback = vim.lsp.buf.clear_references,
  --    desc = "Clear Highlighted References Under Cursor"
  --  })
  --end
end

M.get_on_attach = function(server_name)
  local on_attach_old = vim.lsp.config[server_name] and vim.lsp.config[server_name].on_attach

  local on_attach_new = function(client, bufnr)
    if on_attach_old then
      on_attach_old(client, bufnr)
    end
    M.on_attach(client, bufnr)
  end

  return on_attach_new
end


M.get_on_init = function(server_name)
  local on_init_old = vim.lsp.config[server_name] and vim.lsp.config[server_name].on_init

  local on_init_new = function(client, bufnr)
    if on_init_old then
      on_init_old(client, bufnr)
    end
  end

  return on_init_new
end


return M

