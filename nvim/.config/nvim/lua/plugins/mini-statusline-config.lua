local M = require("mini.statusline")

local section_mode = M.section_mode
M.section_mode = function(args)
  local mode, hl = section_mode(args)
  local register = vim.fn.reg_recording()
  if register ~= "" then
    mode = mode .. " recording @" .. register
  end
  return mode, hl
end

M.section_diagnostics = function(args)
  if M.is_truncated(args.trunc_width) then
    return ""
  end

  local diag_str = vim.diagnostic.status()
  if not diag_str or diag_str == "" then
    return ""
  end

  local icon = "" -- force use icon, cant access to internal data

  return icon .. " " .. diag_str
end

M.section_fileinfo = function(args)
  local encoding = vim.bo.fileencoding or vim.bo.encoding

  if M.is_truncated(args.trunc_width) or vim.bo.buftype ~= "" then
    return encoding
  end

  local format = vim.bo.fileformat

  return string.format("%s[%s]", encoding, format)
end

M.setup({
  use_icons = true,
})

vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
  callback = vim.schedule_wrap(function()
    vim.cmd.redrawstatus()
  end),
  desc = "Refresh the statusline macro recording indicator",
})

vim.opt.laststatus = 2 -- statusline for every window
