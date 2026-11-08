local navic = require("nvim-navic")

navic.setup({
  highlight = true,
  separator = "/",

  depth_limit = 6,
  depth_limit_indicator = "..",

  click = true,
})

local M = {}

function M.get()
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  if not wininfo then
    return ""
  end

  local padding = string.rep(" ", wininfo.textoff or 0)

  local loc = ""
  if require("nvim-navic").is_available() then
    loc = require("nvim-navic").get_location() or "error"
    if vim.trim(loc) == "" then
      loc = "(global scope)"
    end
    return string.format("%%#LineNr#%s%%#NavicText#%s%%*", padding, loc)
  else
    return string.format("%%#LineNr#%s%%#NavicText#(symbol context unavailable)%%*", padding)
  end
end

-- The winbar statusline expression calls this global through v:lua for each window.
_G.navic_winbar = M

-- dont do vim.wo[winid] because will be ugly in split when buffer is not supported
vim.opt.winbar = "%{%v:lua.navic_winbar.get()%}"
--vim.opt.winbar = "%{%v:lua.require("nvim-navic").get_location()%}"
