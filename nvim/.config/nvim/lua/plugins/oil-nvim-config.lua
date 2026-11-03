-- toggle file column detail info
local column_detail = false

-- to show window cwd in winbar
local M = {}

function M.get()
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  if not wininfo then
    return ""
  end

  local winconfig = vim.api.nvim_win_get_config(winid)
  local is_floating = winconfig.relative ~= ""

  local signcol_setting = vim.wo.signcolumn
  local sign_width = 0
  if signcol_setting == "yes" or signcol_setting == "auto" then
    sign_width = 2
  elseif signcol_setting:match("%d") then
    sign_width = tonumber(signcol_setting)
  end

  local total_off = wininfo.textoff or 0
  local num_width = total_off - sign_width
  if num_width < 0 then
    num_width = 0
  end

  local sign_pad = string.rep(" ", sign_width)
  local num_pad = string.rep(" ", num_width)

  local format = ""

  local dir = require("oil").get_current_dir(bufnr)
  if is_floating and dir then
    dir = "cwd: " .. vim.fn.fnamemodify(dir, ":~")
    format = "%%#SignColumn#%s%%#LineNr#%s%%#WinBar#%s%%*"
  else
    dir = ""
    format = "%%#SignColumn#%s%%#LineNr#%s%%#LineNr#%s"
  end

  return string.format(format, sign_pad, num_pad, dir)
end

-- The winbar statusline expression calls this global through v:lua when Oil draws a window.
_G.oil_winbar = M
--

require("oil").setup({
  default_file_explorer = true,

  use_default_keymaps = true,
  keymaps = {
    ["<C-f>"] = { "actions.preview_scroll_down", mode = "n", desc = "Scroll preview down" },
    ["<C-b>"] = { "actions.preview_scroll_up", mode = "n", desc = "Scroll preview up" },

    ["gc"] = {
      callback = function()
        column_detail = not column_detail
        if column_detail then
          require("oil").set_columns({ "permissions", "size", "mtime", "icon" })
        else
          require("oil").set_columns({ "icon" })
        end
      end,
      mode = "n",
      desc = "Toggle column detail",
    },
  },

  view_options = {
    show_hidden = true,
  },

  delete_to_trash = true,

  lsp_file_methods = { enabled = true },

  win_options = {
    winbar = "%{%v:lua.oil_winbar.get()%}",
  },

  float = {
    padding = 2,

    max_width = 0.65,
    max_height = 0.8,

    win_options = {
      winhighlight = table.concat({
        "Normal:OilNormalFloat",
        "FloatBorder:OilFloatBorder",
      }, ","),
    },

    get_win_title = function(winid)
      return "Oil Filesystem"
    end,
    override = function(conf)
      conf.title = "Oil Filesystem"
      conf.title_pos = "center"
      return conf
    end,
  },

  preview_win = {
    win_options = {
      wrap = false,
      list = false,
      spell = false,

      number = true,
      foldcolumn = "0",
      signcolumn = "no",
      cursorcolumn = false,
    },
  },
})

local map = require("core.keymap")

map("n", "<leader>ot", ":tabnew | Oil<CR>", "Oil: open in tab")
map("n", "<leader>of", ":Oil --float<CR>", "Oil: open in float")
map("n", "<leader>ov", ":vnew | Oil<CR>", "Oil: open in split vertically")
map("n", "<leader>oh", ":new | Oil<CR>", "Oil: open in split horizontally")
