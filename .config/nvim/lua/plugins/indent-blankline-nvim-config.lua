
vim.pack.add({
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
})


require("ibl").setup({
  indent = {
    char = "⎸",
    -- char = "▎",
    -- char = "┃",
  },

  whitespace = {
    remove_blankline_trail = false,
  },

  scope = {
    enabled = true,
    show_start = false,
    show_end   = false,
    show_exact_scope   = true,
    injected_languages = true,
  }
})

