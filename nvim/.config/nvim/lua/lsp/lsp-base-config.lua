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
      local command =
        require("core.tools").ensure_executable(name, { commands[name] }, name .. " LSP")
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
  keyn("<C-s>s", vim.lsp.buf.signature_help, "LSP: signature help")

  keyn("<C-s>ic", vim.lsp.buf.incoming_calls, "LSP: incoming calls")
  keyn("<C-s>oc", vim.lsp.buf.outgoing_calls, "LSP: outgoing calls")
  keyn("<C-s>th", vim.lsp.buf.typehierarchy, "LSP: typehierarchy")
  map({ "v", "n" }, "<C-s>ca", function()
    require("fzf-lua").lsp_code_actions({ previewer = "codeaction" })
  end, "LSP: code action (with picker preview)", { buf = bufnr })

  keyn("<C-s>dh", vim.lsp.buf.document_highlight, "LSP: document highlight")
  keyn("<C-s>dc", vim.lsp.buf.declaration, "LSP: declaration")
  keyn("<C-s>cr", vim.lsp.buf.clear_references, "LSP: clear references")

  keyn("<C-s>ws", vim.lsp.buf.workspace_symbol, "LSP: workspace symbol")
  keyn("<C-s>wd", vim.lsp.buf.workspace_diagnostics, "LSP: workspace diagnostics")

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

  -- Harpoon and other plugin windows use <C-s> for their own actions.
  vim.b[bufnr].miniclue_config = {
    triggers = { { mode = "n", keys = "<C-s>" } },
    clues = {
      { mode = "n", keys = "<C-s>c", desc = "+Code actions and references" },
      { mode = "n", keys = "<C-s>d", desc = "+Document commands" },
      { mode = "n", keys = "<C-s>w", desc = "+Workspace commands" },
    },
  }

  -- LSP maps are buffer-local and may arrive after MiniClue's initial trigger scan.
  vim.api.nvim_buf_call(bufnr, function()
    require("mini.clue").ensure_buf_triggers()
  end)
end

M.get_capabilities = function(server_name)
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  local has_blink, blink = pcall(require, "blink.cmp")
  if has_blink then
    return blink.get_lsp_capabilities(nil, true)
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
    for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
  end

  if client.server_capabilities.semanticTokensProvider then
    vim.treesitter.stop(bufnr)
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
