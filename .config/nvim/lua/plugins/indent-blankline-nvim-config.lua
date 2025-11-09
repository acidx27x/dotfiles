
vim.pack.add({
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
  { src = "https://github.com/TheGLander/indent-rainbowline.nvim" },
})


require("ibl.highlights").setup()
local whitespace_hl = require("indent-rainbowline").make_hl_groups({
  colors = nil,
  color_transparency = nil,
  hl = { "IblIndent", "Normal", },
  prefix = "RainbowColor",
  auto_setup = true,
})

require("ibl").setup({
  indent = {
    -- char = "",
    char = "⎸",
    -- char = "▎",
    -- char = "┃",
  },

  whitespace = {
    highlight = whitespace_hl,
    remove_blankline_trail = false,
  },

  scope = {
    char      = "▎",
    enabled   = true,
    show_start = false,
    show_end   = false,
    show_exact_scope   = true,
    injected_languages = true,
  }
})

