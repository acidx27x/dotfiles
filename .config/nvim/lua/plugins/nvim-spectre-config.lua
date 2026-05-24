
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-mini/mini.icons" },
  { src = "https://github.com/nvim-pack/nvim-spectre" },
})


require("spectre").setup({
  default = {
    find = {
      cmd = "rg",
      options = { "ignore-case", },
    },
    replace = {
      cmd = "sd",
    },
  },

  is_block_ui_break = true,
})

vim.keymap.set("n", "<leader>S", require("spectre").toggle,
  { noremap = true, silent = true, desc = "spectre: toggle", })

vim.keymap.set("v", "<leader>S", require("spectre").open_visual,
  { noremap = true, silent = true, desc = "spectre: open and search current word", })
