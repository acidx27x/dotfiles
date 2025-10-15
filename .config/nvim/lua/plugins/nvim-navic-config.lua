
local navic = require("nvim-navic")


navic.setup({
  highlight = true,
  separator = "/",

  depth_limit = 5,
  depth_limit_indicator = "..",

  click = true,
})


local M = {}


function M.get()
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  if not wininfo then return "" end

  local signcol_setting = vim.wo.signcolumn
  local sign_width = 0
  if signcol_setting == "yes" or signcol_setting == "auto" then
    sign_width = 2
  elseif signcol_setting:match("%d") then
    sign_width = tonumber(signcol_setting)
  end

  local total_off = wininfo.textoff or 0
  local num_width = total_off - sign_width
  if num_width < 0 then num_width = 0 end

  local sign_pad = string.rep(" ", sign_width)
  local num_pad  = string.rep(" ", num_width)

  local format = ""

  local loc = ""
  if require("nvim-navic").is_available() then
    loc = require("nvim-navic").get_location() or "error"
    if vim.trim(loc) == "" then
      loc = "(global scope)"
    end
    format = "%%#SignColumn#%s%%#LineNr#%s%%#NavicText#%s%%*"
  else
    format = "%%#SignColumn#%s%%#LineNr#%s%%#LineNr#%s"
  end

  return string.format(format, sign_pad, num_pad, loc)
end


--local cache = {
--  text = "",      -- what winbar displays
--  updating = false,
--}
--
--function M.update_async()
--  if cache.updating then return end
--  cache.updating = true
--
--  vim.schedule(function()
--    -- do heavy computation or async stuff here
--    local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
--    if not wininfo then cache.updating = false; return end
--
--    local signcol_setting = vim.wo.signcolumn
--    local sign_width = 0
--    if signcol_setting == "yes" or signcol_setting == "auto" then
--      sign_width = 2
--    elseif signcol_setting:match("%d") then
--      sign_width = tonumber(signcol_setting)
--    end
--
--    local total_off = wininfo.textoff or 0
--    local num_width = total_off - sign_width
--    if num_width < 0 then num_width = 0 end
--
--    local sign_pad = string.rep(" ", sign_width)
--    local num_pad  = string.rep(" ", num_width)
--
--    local loc = require("nvim-navic").get_location() or ""
--
--    cache.text = string.format("%%#SignColumn#%s%%#LineNr#%s%%*%s", sign_pad, num_pad, loc)
--    cache.updating = false
--
--    -- trigger redraw
--    vim.cmd("redrawstatus")
--  end)
--end
--
--function M.get()
--  -- always schedule an update, but return cached value
--  M.update_async()
--  return cache.text or ""
--end


_G.navic_winbar = M

vim.opt.winbar = "%{%v:lua.navic_winbar.get()%}"

--vim.opt.winbar = "%{%v:lua.require("nvim-navic").get_location()%}"

