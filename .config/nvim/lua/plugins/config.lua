
-- builtin override group
require("nvim-notify-config")
--


-- git group (must be upper than plugins below,
-- bc can be required during config)
require("gitsigns-nvim-config")
--


-- ts group
require("nvim-treesitter-config")
--


-- file explorer group
require("neo-tree-config")

require("oil-nvim-config")
--


-- formatter group
require("conform-nvim-config")
--


-- mini.nvim group
require("mini-pick-config")

require("mini-statusline-config")

require("mini-indentscope-config")

require("mini-tabline-config")

require("mini-comment-config")

require("mini-hipatterns-config")

require("mini-move-config")

require("mini-surround-config")

require("mini-pairs-config")

require("mini-splitjoin-config")

require("mini-bufremove-config")
--


-- term group
require("floaterm-config")
--



-- utils group

-- original code "https://github.com/johnfrankmorgan/whitespace.nvim"
-- changed to skip highlight while editing
require("trailing-whitespace-nvim-config")

require("visual-whitespace-nvim-config")

require("visimatch-nvim-config")

require("hardtime-nvim-config")

require("smartcolumn-nvim-config")

require("multinput-nvim-config")
--

