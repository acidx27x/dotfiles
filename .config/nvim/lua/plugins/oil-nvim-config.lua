
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },  -- uses by default, fb to nvim-web-devicons
  { src = "https://github.com/stevearc/oil.nvim" },
})


-- toggle file column detail info
local column_detail = false


-- to show window cwd in winbar
local M = {}


function M.get()
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  if not wininfo then return "" end

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
  if num_width < 0 then num_width = 0 end

  local sign_pad = string.rep(" ", sign_width)
  local num_pad  = string.rep(" ", num_width)

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


_G.oil_winbar = M
--


require("oil").setup({
  default_file_explorer = true,

  use_default_keymaps = false,
  keymaps = {
    ["<leader>o?"] = { "actions.show_help", mode = "n", desc = "Oil: show help", },
    -- use :q to exit as close may duplicate parent buffer
    -- ["<C-c>"]      = { "actions.close",     mode = "n", desc = "Oil: close", },

    ["<CR>"]        = { "actions.select", mode = "n", desc = "Oil: select", },
    ["<C-s>"] = {
      "actions.select",
      mode = "n", opts = { vertical = true }, desc = "Oil: select in vertical",
    },
    ["<C-h>"] = {
      "actions.select",
      mode = "n", opts = { horizontal = true }, desc = "Oil: select in horizontal",
    },
    ["<C-t>"] = {
      "actions.select",
      mode = "n", opts = { tab = true }, desc = "Oil: select in tab",
    },
    ["<C-p>"] = { "actions.preview", mode = "n", desc = "Oil: toggle preview", },
    ["<C-f>"]   = { "actions.preview_scroll_down", mode = "n", desc = "Oil: scrolll preview up", },
    ["<C-b>"]   = { "actions.preview_scroll_up",   mode = "n", desc = "Oil: scrolll preview down", },

    ["<leader>or"] = { "actions.refresh", mode = "n", desc = "Oil: refresh", },

    ["<leader>ob"] = { "actions.open_cwd", mode = "n", desc = "Oil: open cwd", },
    ["<leader>o-"] = { "actions.parent",   mode = "n", desc = "Oil: open parent", },
    ["<leader>o."] = { "actions.cd",       mode = "n", desc = "Oil: cd", },
    ["<leader>o,"] = {
      "actions.cd",
      opts = { scope = "win" }, mode = "n", desc = "Oil: cd (tab)",
    },
    ["<leader>ox"] = { "actions.open_external", mode = "n", desc = "Oil: open external", },
    ["<leader>os"] = { "actions.change_sort",   mode = "n", desc = "Oil: change sort", },

    ["<leader>oth"] = { "actions.toggle_hidden", mode = "n", desc = "Oil: toggle hidden", },
    ["<leader>ott"] = { "actions.toggle_trash",  mode = "n", desc = "Oil: toggle trash", },
    ["<leader>otc"] = {
      callback = function()
        column_detail = not column_detail
        if column_detail then
          require("oil").set_columns({ "permissions", "size", "mtime", "icon", })
        else
          require("oil").set_columns({ "icon", })
        end
      end,
      mode = "n", desc = "Oil: toggle column detail",
    },
  },

  view_options = {
    show_hidden = true,
  },

  delete_to_trash = true,

  lsp_file_methods = { enabled = false, },

  win_options = {
    winbar = "%{%v:lua.oil_winbar.get()%}",
  },

  float = {
    padding = 2,

    max_width  = 0.65,
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
      wrap  = false,
      list  = false,
      spell = false,

      number       = true,
      foldcolumn   = "0",
      signcolumn   = "no",
      cursorcolumn = false,
    },
  },
})


local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
end

keymap_ns("n", "<leader>ot", ":tabnew | Oil<CR>", "Oil: open in tab")
keymap_ns("n", "<leader>of", ":Oil --float<CR>", "Oil: open in float")
keymap_ns("n", "<leader>ov", ":vnew | Oil<CR>", "Oil: open in split vertically")
keymap_ns("n", "<leader>oh", ":new | Oil<CR>", "Oil: open in split horizontally")
