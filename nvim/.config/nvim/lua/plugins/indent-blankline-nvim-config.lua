local highlights = require("ibl.highlights")
local hooks = require("ibl.hooks")
local colors = { 0xffaacc, 0x7366bd, 0xff79ff, 0x9b81ba }
local whitespace_hl = {}
local active_whitespace_hl = {}
for i = 1, #colors do
  whitespace_hl[i] = "RainbowColor" .. i
  active_whitespace_hl[i] = "RainbowColorActive" .. i
end

-- alpha is the color's share (0..1); the remainder comes from the background.
local function blend(color, bg, alpha)
  local mixed = 0
  -- RGB channels start at bits 16, 8, and 0; modulo 256 extracts each 8-bit channel.
  for shift = 16, 0, -8 do
    local tint = math.floor(color / 2 ^ shift) % 256
    local base = math.floor(bg / 2 ^ shift) % 256
    mixed = mixed + math.floor(tint * alpha + base * (1 - alpha)) * 2 ^ shift
  end
  return mixed
end

-- IBL runs this on setup and after colorscheme changes.
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local fg = normal.fg or 0xffffff
  local bg = normal.bg or 0
  -- Visual tuning: 18% text color keeps guides dim; 55% makes the active guide stand out.
  local indent_fg = blend(fg, bg, 0.18)
  local scope_fg = blend(fg, bg, 0.55)

  vim.api.nvim_set_hl(0, "IblIndent", { fg = indent_fg })

  -- Background tint strength: 7% for ordinary bands, 16% for the active band.
  for i, color in ipairs(colors) do
    vim.api.nvim_set_hl(0, whitespace_hl[i], { fg = indent_fg, bg = blend(color, bg, 0.07) })
    vim.api.nvim_set_hl(0, active_whitespace_hl[i], { fg = scope_fg, bg = blend(color, bg, 0.16) })
  end
end)

-- IBL colors the active guide; extend its tint through the padding after it.
-- A different whitespace highlight marks the next indentation band, where we stop.
hooks.register(hooks.type.VIRTUAL_TEXT, function(_, _, _, virt_text)
  for column, chunk in ipairs(virt_text) do
    for _, scope in ipairs(highlights.scope) do
      if vim.tbl_contains(chunk[2], scope.char) then
        for i = column + 1, #virt_text do
          if virt_text[i][2][1] ~= chunk[2][1] then
            break
          end
          table.insert(virt_text[i][2], scope.char)
        end
        return virt_text
      end
    end
  end
  return virt_text
end)

local indent_char = "▏"
require("ibl").setup({
  indent = {
    char = indent_char,
    tab_char = indent_char,
  },

  whitespace = {
    highlight = whitespace_hl,
    remove_blankline_trail = false,
  },

  scope = {
    char = indent_char,
    highlight = active_whitespace_hl,
    enabled = true,
    show_start = false,
    show_end = false,
    show_exact_scope = true,
    injected_languages = true,
  },
})
