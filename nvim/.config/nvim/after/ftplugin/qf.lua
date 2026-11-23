local map = require("core.keymap")

local severities = {
  { label = "Errors", type = "E" },
  { label = "Warnings", type = "W" },
  { label = "Info", type = "I" },
  { label = "Hints and notes", type = "N" },
}

map("n", "<leader>es", function()
  local win = vim.api.nvim_get_current_win()
  local is_loclist = vim.fn.getwininfo(win)[1].loclist == 1
  local function get_list(what)
    if is_loclist then
      return vim.fn.getloclist(win, what)
    end
    return vim.fn.getqflist(what)
  end

  local id = get_list({ id = 0 }).id
  vim.ui.select(severities, {
    prompt = "Filter by diagnostic severity> ",
    format_item = function(severity)
      return severity.label
    end,
  }, function(severity)
    if not severity or not vim.api.nvim_win_is_valid(win) then
      return
    end

    local list = get_list({ id = 0, title = 0, items = 0 })
    if list.id ~= id then
      return
    end

    local items = vim.tbl_filter(function(item)
      return item.type:upper() == severity.type
    end, list.items)
    if #items == 0 then
      vim.notify("No matching entries in this list", vim.log.levels.INFO)
      return
    end

    local title = list.title .. " (" .. severity.label .. ")"
    local filtered = { nr = "$", title = title, items = items }
    if is_loclist then
      vim.fn.setloclist(win, {}, " ", filtered)
    else
      vim.fn.setqflist({}, " ", filtered)
    end
  end)
end, "quickfix: filter by severity", { buf = 0 })
