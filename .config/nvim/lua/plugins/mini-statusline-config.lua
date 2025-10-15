
local M = require("mini.statusline")


M.section_fileinfo = function(args)
  local encoding = vim.bo.fileencoding or vim.bo.encoding

  if M.is_truncated(args.trunc_width) or vim.bo.buftype ~= '' then
    return encoding
  end

  local format = vim.bo.fileformat

  return string.format("%s[%s]", encoding, format)
end


M.setup({
  -- dont like icons and anyway
  -- cant access to internals bc override default function below
  use_icons = false,

  default_content_active = function()  -- TODO mb change trunc_width in future
    local mode, mode_hl = M.section_mode({ trunc_width = 120 })
    local git           = M.section_git({ trunc_width = 40 })
    local diff          = M.section_diff({ trunc_width = 75 })
    local diagnostics   = M.section_diagnostics({ trunc_width = 75 })
    local lsp           = M.section_lsp({ trunc_width = 75 })
    local filename      = M.section_filename({ trunc_width = 140 })
    local fileinfo      = M.section_fileinfo({ trunc_width = 40 })
    local location      = M.section_location({ trunc_width = 75 })

    return M.combine_groups({
      { hl = mode_hl,                  strings = { mode, } },
      { hl = 'MiniStatuslineDevinfo',  strings = { git, diff, diagnostics, lsp, } },
      '%<', -- Mark general truncate point
      { hl = 'MiniStatuslineFilename', strings = { filename, } },
      '%=', -- End left alignment
      { hl = 'MiniStatuslineFileinfo', strings = { fileinfo, } },
      { hl = mode_hl,                  strings = { location, } },
    })
  end
})


vim.opt.laststatus = 2  -- statusline for every window

