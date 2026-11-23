-- builtin override and common group
local mux = require("core.tools").detect_mux()
local backend
if mux then
  require("plugins.spec").load(mux)
  if mux == "tmux" then
    backend = "smart-splits-backend-tmux"
    require(backend).setup({ resize_amount = 2 })
  else
    backend = "smart-splits-backend-zellij-lua"
    require(backend).setup({ move_cursor = { pane_or_tab = false } })
  end
end
require("smart-splits").setup({
  resize = { amount = 2 },
  move = { at_edge = "stop" },
  mux = { backend = backend },
})

require("plugins.mini-notify-config") -- vim.notify
require("plugins.tiny-cmdline-nvim-config")

require("plugins.multinput-nvim-config") -- vim.ui.input

require("plugins.icons-config")
require("plugins.diffview-plus-nvim-config")
require("plugins.fzf-lua-config") -- also overrides vim.ui.select
require("plugins.auto-session-config")
--

-- ts group, lots of pluggins use it
require("plugins.nvim-treesitter-config")
--

-- file explorer group
require("plugins.oil-nvim-config")
require("plugins.mini-files-config")
--

-- mini.nvim group
require("plugins.mini-bracketed-config")

require("plugins.mini-statusline-config")

require("plugins.mini-tabline-config")

require("plugins.mini-comment-config")

require("plugins.mini-hipatterns-config")

require("plugins.mini-move-config")

require("plugins.mini-operators-config")

require("plugins.mini-surround-config")

require("plugins.leap-config")

require("plugins.mini-pairs-config")

require("plugins.mini-splitjoin-config")

require("plugins.mini-bufremove-config")

require("plugins.mini-trailspace-config")

--

-- utils group
require("plugins.matchparen-nvim-config")
require("plugins.quicker-nvim-config")
--

-- Register optional feature mappings now; their callbacks load and configure plugins on use.
require("plugins.auto-save-nvim-config")
require("plugins.harpoon-config")
require("plugins.no-neck-pain-nvim-config")
require("plugins.grug-far-nvim-config")
require("plugins.snipe-nvim-config")
require("plugins.visual-whitespace-nvim-config")
require("dap.config")

require("plugins.conform-nvim-config").setup()

-- Load buffer UI before the first existing file is read, or when the first new file is made.
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  once = true,
  callback = function()
    local lazy = require("plugins.lazy")
    for _, module in ipairs({
      "plugins.auto-save-nvim-config",
      "plugins.gitsigns-nvim-config",
      "plugins.indent-blankline-nvim-config",
      "plugins.smartcolumn-nvim-config",
      "plugins.visimatch-nvim-config",
      "plugins.visual-whitespace-nvim-config",
    }) do
      lazy.load("buffer_ui", module)
    end
  end,
  desc = "Load plugins used by normal file buffers",
})
