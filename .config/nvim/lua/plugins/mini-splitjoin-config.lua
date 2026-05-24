
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.splitjoin" },
})


require("mini.splitjoin").setup({
  mappings = {
    toggle = "",
    split = "S",
    join = "J",
  },

  detect = {
    brackets = { "%b()", "%b[]", "%b{}", "%b<>", },
    exclude_regions = { "%b()", "%b[]", "%b{}", "%b<>", '%b""', "%b''", },
  },
})
