require("ibl.highlights").setup()
local hooks = require("ibl.hooks")
local colors = { 0xffaacc, 0x7366bd, 0xff79ff, 0x9b81ba }
local whitespace_hl = {}
for i = 1, #colors do
  whitespace_hl[i] = "RainbowColor" .. i
end

local function setup_colors()
  local indent = vim.api.nvim_get_hl(0, { name = "IblIndent", link = false })
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local fg = indent.fg or normal.fg
  local bg = indent.bg or normal.bg or 0

  for i, color in ipairs(colors) do
    local mixed = 0
    for shift = 16, 0, -8 do
      local tint = math.floor(color / 2 ^ shift) % 256
      local base = math.floor(bg / 2 ^ shift) % 256
      mixed = mixed + math.floor(tint * 0.07 + base * 0.93) * 2 ^ shift
    end
    vim.api.nvim_set_hl(0, whitespace_hl[i], { fg = fg, bg = mixed })
  end
end

setup_colors()
-- IBL recreates highlights after colorscheme changes; rebuild the derived whitespace colors then.
hooks.register(hooks.type.HIGHLIGHT_SETUP, setup_colors)

local is_mac = vim.uv.os_uname().sysname == "Darwin"
local is_linux = vim.uv.os_uname().sysname == "Linux"

local indent_char = "|"
if is_linux then
  indent_char = "⎜"
end
if is_mac then
  indent_char = "⎸"
end

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
    char = "▎",
    enabled = true,
    show_start = false,
    show_end = false,
    show_exact_scope = true,
    injected_languages = true,
  },
})
