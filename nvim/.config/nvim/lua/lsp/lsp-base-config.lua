local M = {}
local map = require("core.keymap")

M.enable = function(name, filetypes)
  local commands = {
    clangd = "clangd",
    neocmake = "neocmakelsp",
    ruff = "ruff",
    ty = "ty",
  }
  local autocmd
  autocmd = vim.api.nvim_create_autocmd("FileType", {
    pattern = filetypes,
    callback = function()
      local command = require("core.tools").ensure_executable(
        name,
        { commands[name] },
        name .. " LSP"
      )
      if command then
        vim.lsp.config[name].cmd[1] = command
        vim.api.nvim_del_autocmd(autocmd)
        vim.lsp.enable(name)
      end
    end,
  })
end

M.lsp_keymaps = function(bufnr)
  local function keyn(key, func, desc)
    map("n", key, func, desc, { buf = bufnr })
  end

  -- base goto smth lsp operations
  keyn("gd", vim.lsp.buf.definition, "LSP: definition")
  keyn("gy", vim.lsp.buf.type_definition, "LSP: type definition")
  keyn("gi", vim.lsp.buf.implementation, "LSP: implementation")

  local function preview(action)
    return function()
      require("plugins.lazy").load("lsp_preview", "lsp.goto-preview-config")
      require("goto-preview")[action]()
    end
  end
  keyn("gpd", preview("goto_preview_definition"), "LSP: preview definition")
  keyn("gpy", preview("goto_preview_type_definition"), "LSP: preview type definition")
  keyn("gpc", preview("goto_preview_declaration"), "LSP: preview declaration")
  keyn("gpr", preview("goto_preview_references"), "LSP: preview references")
  keyn("gpi", preview("goto_preview_implementation"), "LSP: preview implementation")
  keyn("gpq", preview("close_all_win"), "LSP: preview close all")
  --

  -- additional lsp operations (C-s because lSp)
  keyn("<C-s>h", vim.lsp.buf.hover, "LSP: hover")
  keyn("<C-s>s", vim.lsp.buf.signature_help, "LSP: signature help")

  keyn("<C-s>rn", vim.lsp.buf.rename, "LSP: rename")
  keyn("<C-s>ic", vim.lsp.buf.incoming_calls, "LSP: incoming calls")
  keyn("<C-s>oc", vim.lsp.buf.outgoing_calls, "LSP: outgoing calls")
  keyn("<C-s>th", vim.lsp.buf.typehierarchy, "LSP: typehierarchy")
  map({ "v", "n" }, "<C-s>ca", function()
    local command = require("core.tools").ensure_executable(
      "diff-so-fancy",
      { "diff-so-fancy" },
      "Code action preview",
      true
    )
    require("plugins.lazy").load("lsp_actions", "lsp.actions-preview-nvim-config", command)
    require("actions-preview").code_actions()
  end, "LSP: code action (with picker preview)", { buf = bufnr })

  keyn("<C-s>ds", vim.lsp.buf.document_symbol, "LSP: document symbol")
  keyn("<C-s>dh", vim.lsp.buf.document_highlight, "LSP: document highlight")
  keyn("<C-s>dc", vim.lsp.buf.declaration, "LSP: declaration")
  keyn("<C-s>cr", vim.lsp.buf.clear_references, "LSP: clear references")

  keyn("<C-s>ws", vim.lsp.buf.workspace_symbol, "LSP: workspace symbol")
  keyn("<C-s>wd", vim.lsp.buf.workspace_diagnostics, "LSP: workspace diagnostics")
  -- TODO vim.lsp.buf.selection_range

  keyn("<C-s>l", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
  end, "LSP: toggle inlay hint (buffer)")
  keyn("<C-s>L", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, "LSP: toggle inlay hint")

  local function symbol_usage(action)
    return function()
      require("plugins.lazy").load("symbol_usage", "lsp.symbol-usage-nvim-config")
      require("symbol-usage")[action]()
    end
  end
  keyn("<C-s>u", symbol_usage("toggle"), "LSP: symbol usage toggle")
  keyn("<C-s>U", symbol_usage("toggle_globally"), "LSP: symbol usage toggle (global)")
  --

  -- Keep Neovim's readable default LSP keys available beside the custom groups.
  keyn("K", vim.lsp.buf.hover, "LSP: hover")
  keyn("gri", vim.lsp.buf.implementation, "LSP: implementation (native key)")
  keyn("grn", vim.lsp.buf.rename, "LSP: rename (native key)")
  keyn("grr", vim.lsp.buf.references, "LSP: references (native key)")
  keyn("grt", vim.lsp.buf.type_definition, "LSP: type definition (native key)")
  keyn("gO", vim.lsp.buf.document_symbol, "LSP: document symbols (native key)")
  map({ "n", "v" }, "gra", vim.lsp.buf.code_action, "LSP: code action", { buf = bufnr })

  vim.api.nvim_buf_call(bufnr, function()
    require("mini.clue").ensure_buf_triggers()
  end)
end

M.get_capabilities = function(server_name)
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- HINT: for large number of files may be useful
  -- capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
  --

  local has_blink, blink = pcall(require, "blink.cmp")
  if has_blink then
    return blink.get_lsp_capabilities(capabilities)
  else
    vim.notify(
      "blink.cmp is not installed, falling back to default lsp capabilities",
      vim.log.levels.WARN,
      { title = "LSP" }
    )
    return capabilities
  end
end

M.on_attach = function(client, bufnr)
  M.lsp_keymaps(bufnr)

  --  this options are check before action and can be overrided by custom callback on_attach
  if client.server_capabilities.foldingRangeProvider then
    vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
  end

  if client.server_capabilities.semanticTokensProvider then
    vim.treesitter.stop(bufnr)
  end

  if client.server_capabilities.completionProvider then
    vim.bo[bufnr].omnifunc = nil
  end

  if client.server_capabilities.documentSymbolProvider then
    local has_navic, navic = pcall(require, "nvim-navic")
    if has_navic then
      navic.attach(client, bufnr)
    else
      vim.notify(
        "nvim-navic is not installed, falling back to default winbar",
        vim.log.levels.WARN,
        { title = "LSP" }
      )
    end
  end
  --
end

M.get_on_attach = function(server_name, override)
  local on_attach_old = vim.lsp.config[server_name] and vim.lsp.config[server_name].on_attach

  local on_attach_new = function(client, bufnr)
    if on_attach_old then
      on_attach_old(client, bufnr)
    end
    if override then
      override(client, bufnr)
    end -- option to pass custom on_attach to override default settings
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
