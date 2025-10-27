
-- builtin override group
vim.pack.add({
  { src = "https://github.com/rcarriga/nvim-notify" },
})
require("nvim-notify-config")
--


-- git group (must be upper than plugins below,
-- bc can be required during config)
vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})
require("gitsigns-nvim-config")
--


-- ts group
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})
require("nvim-treesitter-config")
--


-- file explorer group
vim.pack.add({
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
})
require("neo-tree-config")

vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim" },
})
require("oil-nvim-config")
--


-- formatter group
vim.pack.add({
  { src = "https://github.com/stevearc/conform.nvim" },
})
require("conform-nvim-config")
--


-- mini.nvim group
vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/nvim-mini/mini.statusline" },
})
require("mini-pick-config")

require("mini-statusline-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.indentscope" },
})
require("mini-indentscope-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.tabline" },
})
require("mini-tabline-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.comment" },
})
require("mini-comment-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.hipatterns" },
})
require("mini-hipatterns-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.move" },
})
require("mini-move-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.surround" },
})
require("mini-surround-config")

require("mini-pairs-config")

require("mini-splitjoin-config")

require("mini-bufremove-config")
--


-- term group
vim.pack.add({
  { src = "https://github.com/nvzone/volt" },
  { src = "https://github.com/nvzone/floaterm" },
})
require("floaterm-config")
--



-- utils group

-- original code "https://github.com/johnfrankmorgan/whitespace.nvim"
-- changed to skip highlight while editing
require("trailing-whitespace-nvim-config")

vim.pack.add({
  { src = "https://github.com/mcauley-penney/visual-whitespace.nvim" },
})
require("visual-whitespace-nvim-config")

vim.pack.add({
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/m4xshen/hardtime.nvim" },
})
require("visimatch-nvim-config")

require("hardtime-nvim-config")

vim.pack.add({
  { src = "https://github.com/m4xshen/smartcolumn.nvim" },
})
require("smartcolumn-nvim-config")

require("multinput-nvim-config")
--

