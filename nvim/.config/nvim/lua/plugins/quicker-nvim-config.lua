local quicker = require("quicker")

local function show_context()
  local win = vim.api.nvim_get_current_win()
  local is_loclist = vim.fn.getwininfo(win)[1].loclist == 1
  local fields = { items = 0, title = 0, idx = 0 }
  local list = is_loclist and vim.fn.getloclist(win, fields) or vim.fn.getqflist(fields)
  if #list.items == 0 then
    return
  end

  -- Quicker collapses entries on the same source line when expanding context.
  list.nr = "$"
  list.title = list.title .. " (source context)"
  local result
  if is_loclist then
    result = vim.fn.setloclist(win, {}, " ", list)
  else
    result = vim.fn.setqflist({}, " ", list)
  end
  if result == 0 then
    quicker.expand()
  end
end

quicker.setup({
  edit = { enabled = false },
  type_icons = {
    E = "E",
    W = "W",
    I = "I",
    N = "H", -- Neovim uses N for hints in quickfix and location lists.
    H = "H",
  },
  keys = {
    { "<leader>ec", show_context, desc = "quickfix: show source context" },
    {
      "<leader>ew",
      function()
        local wrap = not vim.wo.wrap
        vim.wo.wrap = wrap
        vim.wo.linebreak = wrap
      end,
      desc = "quickfix: toggle word wrap",
    },
  },
})
