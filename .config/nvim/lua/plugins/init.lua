
-- ts group
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})
require("nvim-treesitter-config")
--


-- lsp group
vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

vim.pack.add({
  {
    src     = "https://github.com/Saghen/blink.cmp",
    version = "v1.7.0"  -- need to download binary
  },
})
require("blink-cmp-config")

vim.pack.add({
  { src = "https://github.com/SmiteshP/nvim-navic" },
})
require("nvim-navic-config")
--


-- git group (must be upper than pluggins below, bc can be required during config)
vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})
require("gitsigns-nvim-config")
--


-- neo-tree group
vim.pack.add({
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
})
require("neo-tree-config")
--


-- mini.nvim group
vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/nvim-mini/mini.statusline" },
})
require("mini-statusline-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.indentscope" },
})
require("mini-indentscope-config")

vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.tabline" },
})
require("mini-tabline-config")
--



-- utils group
-- original code "https://github.com/johnfrankmorgan/whitespace.nvim" changed to skip highlight while editing
require("trailing-whitespace-nvim-config")

vim.pack.add({
  { src = "https://github.com/mcauley-penney/visual-whitespace.nvim" },
})
require("visual-whitespace-nvim-config")
--



-- disabled group

-- lualine group
--vim.pack.add({
--  { src = "https://github.com/nvim-lualine/lualine.nvim" },
--})
--require("lualine-config")
--


-- barbar group
--vim.pack.add({
--  { src = "https://github.com/lewis6991/gitsigns.nvim" },
--  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
--  { src = "https://github.com/romgrk/barbar.nvim" },
--})
--require("barbar-nvim-config")
--

--

