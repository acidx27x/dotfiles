
vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/nvim-mini/mini.icons" },  -- uses by default, fb to nvim-web-devicons
  { src = "https://github.com/nvim-mini/mini.statusline" },
})


local M = require("mini.statusline")


M.section_diagnostics = function(args)
  if M.is_truncated(args.trunc_width) then return "" end

  local diag_str = vim.diagnostic.status()
  if not diag_str or diag_str == "" then return "" end

  local icon = ""  -- force use icon, cant access to internal data

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


vim.opt.laststatus = 2  -- statusline for every window
