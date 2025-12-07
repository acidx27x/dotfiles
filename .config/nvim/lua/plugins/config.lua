
-- builtin override and common group
require("nvim-notify-config")  -- vim.notify

require("multinput-nvim-config")  -- vim.ui.input

require("icons-config")
--


-- ts group, lots of pluggins use it
require("nvim-treesitter-config")
--


-- git group (must be upper than plugins below,
-- bc can be required during config)
require("gitsigns-nvim-config")
--


-- file explorer group
require("neo-tree-config")

require("oil-nvim-config")

require("harpoon-config")

require("snipe-nvim-config")

require("nvim-spectre-config")
--


-- formatter group
require("conform-nvim-config")
--


-- mini.nvim group
require("mini-pick-config")  -- WARN: also overrides builtin vim.ui.select

require("mini-statusline-config")

require("mini-tabline-config")

require("mini-comment-config")

require("mini-hipatterns-config")

require("mini-move-config")

require("mini-surround-config")

require("mini-pairs-config")

require("mini-splitjoin-config")

require("mini-bufremove-config")

require("mini-trailspace-config")
--


-- term group
require("floaterm-config")
--



-- utils group
require("indent-blankline-nvim-config")

-- original code "https://github.com/johnfrankmorgan/whitespace.nvim"
-- changed to skip highlight while editing
-- require("trailing-whitespace-nvim-config")

require("visual-whitespace-nvim-config")

require("visimatch-nvim-config")

-- require("hardtime-nvim-config")

require("smartcolumn-nvim-config")

require("matchparen-nvim-config")

require("no-neck-pain-nvim-config")

require("auto-save-nvim-config")
--

