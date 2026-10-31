local M = {}
local loaded_groups = {}

-- Native package layout and moderate lazy loading follow:
-- https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack

local eager = {
  { src = "https://github.com/saghen/blink.lib" },
  { src = "https://github.com/Saghen/blink.cmp", version = "main" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/rafamadriz/friendly-snippets" },
  { src = "https://github.com/rebelot/kanagawa.nvim" },
  { src = "https://github.com/monkoose/matchparen.nvim" },
  { src = "https://github.com/nvim-mini/mini.bufremove" },
  { src = "https://github.com/nvim-mini/mini.clue" },
  { src = "https://github.com/nvim-mini/mini.comment" },
  { src = "https://github.com/nvim-mini/mini.extra" },
  { src = "https://github.com/nvim-mini/mini.hipatterns" },
  { src = "https://github.com/nvim-mini/mini.icons" },
  { src = "https://github.com/nvim-mini/mini.move" },
  { src = "https://github.com/nvim-mini/mini.pairs" },
  { src = "https://github.com/nvim-mini/mini.pick" },
  { src = "https://github.com/nvim-mini/mini.splitjoin" },
  { src = "https://github.com/nvim-mini/mini.statusline" },
  { src = "https://github.com/nvim-mini/mini.surround" },
  { src = "https://github.com/nvim-mini/mini.tabline" },
  { src = "https://github.com/nvim-mini/mini.trailspace" },
  { src = "https://github.com/r0nsha/multinput.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/SmiteshP/nvim-navic" },
  { src = "https://github.com/rcarriga/nvim-notify" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/stevearc/oil.nvim" },
}

local optional = {
  { src = "https://github.com/aznhe21/actions-preview.nvim" },
  { src = "https://github.com/okuuva/auto-save.nvim" },
  { src = "https://github.com/nvzone/floaterm" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/rmagatti/goto-preview" },
  { src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
  { src = "https://github.com/rmagatti/logger.nvim" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-pack/nvim-spectre" },
  { src = "https://github.com/m4xshen/smartcolumn.nvim" },
  { src = "https://github.com/leath-dub/snipe.nvim" },
  { src = "https://github.com/Wansmer/symbol-usage.nvim" },
  { src = "https://github.com/wurli/visimatch.nvim" },
  { src = "https://github.com/mcauley-penney/visual-whitespace.nvim" },
  { src = "https://github.com/shortcuts/no-neck-pain.nvim" },
  { src = "https://github.com/nvzone/volt" },
}

M.groups = {
  buffer_ui = {
    "auto-save.nvim",
    "gitsigns.nvim",
    "indent-blankline.nvim",
    "smartcolumn.nvim",
    "visimatch.nvim",
    "visual-whitespace.nvim",
  },
  dap = { "nvim-nio", "nvim-dap", "nvim-dap-ui", "nvim-dap-virtual-text" },
  floaterm = { "volt", "floaterm" },
  harpoon = { "plenary.nvim", "harpoon" },
  lsp_actions = { "actions-preview.nvim" },
  lsp_preview = { "logger.nvim", "goto-preview" },
  no_neck_pain = { "no-neck-pain.nvim" },
  snipe = { "snipe.nvim" },
  spectre = { "plenary.nvim", "nvim-spectre" },
  symbol_usage = { "symbol-usage.nvim" },
}

function M.setup()
  local treesitter_action
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(args)
      if args.data.spec.name ~= "nvim-treesitter" then
        return
      end

      if args.data.kind == "install" then
        treesitter_action = "TSInstallConfigured"
      elseif args.data.kind == "update" then
        treesitter_action = "TSUpdate"
      else
        return
      end

      if vim.v.vim_did_enter == 1 then
        vim.cmd.packadd("nvim-treesitter")
        vim.cmd(treesitter_action)
        treesitter_action = nil
      end
    end,
    desc = "Install or update Tree-sitter parsers after package changes",
  })

  -- PackChanged can fire during vim.pack.add, before plugins.config defines the TS commands.
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      if treesitter_action then
        vim.cmd(treesitter_action)
      end
    end,
    desc = "Finish a pending Tree-sitter package hook",
  })

  vim.pack.add(eager)
  -- Register optional packages now so startup mappings can load them on demand.
  vim.pack.add(optional, { load = function() end })
end

function M.load(group)
  if loaded_groups[group] then
    return
  end

  for _, name in ipairs(assert(M.groups[group], "unknown plugin group: " .. group)) do
    vim.cmd.packadd(name)
  end
  loaded_groups[group] = true
end

return M
