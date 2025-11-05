
vim.pack.add({
  { src = "https://github.com/aznhe21/actions-preview.nvim" },
})


require("actions-preview").setup({
  diff = {
    algorithm = "patience",
    ignore_whitespace = true,
  },

  backend = { "minipick", },
})

