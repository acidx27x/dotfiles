
local M = {}


M.setup = function(_)
  vim.diagnostic.config({
    virtual_text = {
      prefix = '▣',
      source = "if_many",
    },
    underline        = true,
    severity_sort    = true,
    update_in_insert = false,
    float = {
      focusable = true,
      style     = "minimal",
      source    = "if_many",
      header    = '',
      prefix    = '',
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
end


M.lsp_keymaps = function(bufnr)
  local function getopts(desc)
    return { noremap = true, silent = true, buffer = bufnr, desc = desc }
  end
  local function keyn(key, func, opts)
    vim.keymap.set("n", key, func, opts)
  end

  keyn("gd", vim.lsp.buf.definition,      getopts("vim.lsp.buf.definition"))
  keyn("gy", vim.lsp.buf.type_definition, getopts("vim.lsp.buf.type_definition"))
  keyn("gc", vim.lsp.buf.declaration,     getopts("vim.lsp.buf.declaration"))
  keyn("gr", vim.lsp.buf.references,      getopts("vim.lsp.buf.references"))
  keyn("gi", vim.lsp.buf.implementation,  getopts("vim.lsp.buf.implementation"))
  keyn("gs", vim.lsp.buf.document_symbol, getopts("vim.lsp.buf.document_symbol"))

  -- C-s because lSp
  keyn("<C-s>k", vim.lsp.buf.hover,          getopts("vim.lsp.buf.hover"))
  keyn("<C-s>s", vim.lsp.buf.signature_help, getopts("vim.lsp.buf.signature_help"))

  keyn("<C-s>rn", vim.lsp.buf.rename,      getopts("vim.lsp.buf.rename"))
  keyn("<C-s>ca", vim.lsp.buf.code_action, getopts("vim.lsp.buf.code_action"))

  keyn("<C-w>dl", vim.diagnostic.setloclist, getopts("vim.diagnostic.setloclist"))
  keyn("<C-w>do", vim.diagnostic.open_float, getopts("vim.diagnostic.open_float"))
  keyn("]d", function()
    vim.diagnostic.jump({ count = 1 })
  end,  getopts("vim.diagnostic.jump/next"))
  keyn("[d", function()
    vim.diagnostic.jump({ count = -1 })
  end, getopts("vim.diagnostic.jump/prev"))

  keyn("<C-s>i", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
  end, getopts("vim.lsp.inlay_hint.enable/disable buffer"))
  keyn("<C-s>I", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, getopts("vim.lsp.inlay_hint.enable/disable buffer"))

  keyn("<C-s>h", vim.lsp.buf.document_highlight, getopts("vim.lsp.buf.document_highlight"))
  keyn("<C-s>c", vim.lsp.buf.clear_references,   getopts("vim.lsp.buf.clear_references"))

  -- delete remapped combinations
  vim.keymap.set('n', 'K',      "<Nop>", { buffer = bufnr })  -- hover
  vim.keymap.set('n', "gri",    "<Nop>", { buffer = bufnr })  -- implementation
  vim.keymap.set('n', "grn",    "<Nop>", { buffer = bufnr })  -- rename
  vim.keymap.set('n', "grr",    "<Nop>", { buffer = bufnr })  -- references
  vim.keymap.set('n', "grt",    "<Nop>", { buffer = bufnr })  -- type_definition
  vim.keymap.set('n', "gO",     "<Nop>", { buffer = bufnr })  -- document_symbol
  vim.keymap.set('n', "<C-w>d", "<Nop>", { buffer = bufnr })  -- open_float

  vim.keymap.set({'n', 'v'}, "gra",   "<Nop>", { buffer = bufnr })  -- code_action
  vim.keymap.set( 'i',       "<C-s>", "<Nop>", { buffer = bufnr })  -- signature_help
end


M.get_capabilities = function(server_name)
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- shared override capabilities
  if capabilities.textDocument.foldingRange then
    vim.o.foldmethod = "expr"
    vim.o.foldexpr   = "v:lua.vim.lsp.foldexpr()"
  end

  capabilities.textDocument.completion.completionItem = {
    snippetSupport = false,
  }
  --

  return require("blink.cmp").get_lsp_capabilities(capabilities)
end


M.on_attach = function(client, bufnr)
  M.lsp_keymaps(bufnr)

  -- shared override capabilities
  vim.bo[bufnr].formatexpr = ""
  client.server_capabilities.documentFormattingProvider       = false
  client.server_capabilities.documentRangeFormattingProvider  = false
  client.server_capabilities.documentOnTypeFormattingProvider = false
  --

  if client.server_capabilities.documentSymbolProvider then
    require("nvim-navic").attach(client, bufnr)
  end

  if client.server_capabilities.semanticTokensProvider then
    vim.treesitter.stop(bufnr)
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

