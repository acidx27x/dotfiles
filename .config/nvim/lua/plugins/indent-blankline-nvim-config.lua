
vim.pack.add({
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
  { src = "https://github.com/TheGLander/indent-rainbowline.nvim" },
})


require("ibl.highlights").setup()
local whitespace_hl = require("indent-rainbowline").make_hl_groups({
  colors = { 0xffaacc, 0x7366bd, 0xff79ff, 0x9b81ba, },
  color_transparency = nil,
  hl = { "IblIndent", "Normal", },
  prefix = "RainbowColor",
  auto_setup = true,
})

local is_mac     = vim.loop.os_uname().sysname == "Darwin"
local is_linux   = vim.loop.os_uname().sysname == "Linux"
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"

local indent_char = "|"
if is_linux then indent_char = "⎜" end
if is_mac   then indent_char = "⎸" end

require("ibl").setup({
  indent = {
    -- char = "⎜",
    -- char = "▎",
    -- char = "┃",
    char = indent_char,
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

