-- builtin override and common group
require("plugins.nvim-notify-config") -- vim.notify

require("plugins.multinput-nvim-config") -- vim.ui.input

require("plugins.icons-config")
--

-- ts group, lots of pluggins use it
require("plugins.nvim-treesitter-config")
--

-- file explorer group
require("plugins.oil-nvim-config")
--

-- mini.nvim group
require("plugins.mini-pick-config") -- WARN: also overrides builtin vim.ui.select

require("plugins.mini-statusline-config")

require("plugins.mini-tabline-config")

require("plugins.mini-comment-config")

require("plugins.mini-hipatterns-config")

require("plugins.mini-move-config")

require("plugins.mini-surround-config")

require("plugins.mini-pairs-config")

require("plugins.mini-splitjoin-config")

require("plugins.mini-bufremove-config")

require("plugins.mini-trailspace-config")

require("plugins.mini-clue-config")
--

-- utils group
require("plugins.matchparen-nvim-config")
--

-- Register optional feature mappings before their plugins load.
require("plugins.auto-save-nvim-config")
require("plugins.conform-nvim-config")
require("plugins.floaterm-config")
require("plugins.harpoon-config")
require("plugins.no-neck-pain-nvim-config")
require("plugins.nvim-spectre-config")
require("plugins.snipe-nvim-config")
require("plugins.visual-whitespace-nvim-config")
require("dap.config")

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
