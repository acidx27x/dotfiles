
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.surround" },
})


require("mini.surround").setup({
  mappings = {
    add     = "sa",
    delete  = "sd",
    replace = "sr",

    find      = "sf",
    find_left = "sF",
    highlight = "sh",

    suffix_last = "l", -- Suffix to search with "prev" method
    suffix_next = "n", -- Suffix to search with "next" method
  },
})

