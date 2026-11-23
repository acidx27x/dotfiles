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
  if dir then
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

local function set_cwd(cmd)
  local dir = require("oil").get_current_dir()
  local target = vim.w.oil_original_win or vim.api.nvim_get_current_win()
  if not dir or not vim.api.nvim_win_is_valid(target) then
    return
  end

  vim.api.nvim_win_call(target, function()
    vim.cmd({ cmd = cmd, args = { dir } })
  end)
end

require("oil").setup({
  default_file_explorer = true,

  use_default_keymaps = true,
  keymaps = {
    ["<C-f>"] = { "actions.preview_scroll_down", mode = "n", desc = "Scroll preview down" },
    ["<C-b>"] = { "actions.preview_scroll_up", mode = "n", desc = "Scroll preview up" },

    ["<leader>fd"] = {
      callback = function()
        local dir = require("oil").get_current_dir()
        if not dir then
          vim.notify("Copy directory requires a local Oil directory", vim.log.levels.WARN)
          return
        end
        vim.fn.setreg("+", dir)
        print("directory:", dir)
      end,
      mode = "n",
      desc = "Copy Oil directory path",
    },
    ["<leader>fp"] = {
      callback = function()
        local oil = require("oil")
        local dir = oil.get_current_dir()
        local entry = oil.get_cursor_entry()
        if not dir then
          vim.notify("Copy entry path requires a local Oil directory", vim.log.levels.WARN)
          return
        end
        if not entry then
          return
        end
        local path = dir .. entry.name
        vim.fn.setreg("+", path)
        print("file:", path)
      end,
      mode = "n",
      desc = "Copy Oil entry path",
    },

    ["gf"] = {
      callback = function()
        local oil = require("oil")
        local dir = oil.get_current_dir()
        if not dir then
          vim.notify("Recursive file search requires a local Oil directory", vim.log.levels.WARN)
          return
        end
        local opts = { cwd = dir }
        if vim.w.oil_original_win then
          local view = vim.fn.winsaveview()
          local accepted = false
          opts.fn_selected = function(selected, picker_opts)
            local actions = require("fzf-lua.actions")
            local key, entries = actions.normalize_selected(selected, picker_opts)
            accepted = key ~= "esc"
              and key ~= "ctrl-c"
              and key ~= "ctrl-q"
              and entries ~= nil
              and #entries > 0
            actions.act(selected, picker_opts)
          end
          opts.winopts = {
            on_close = function()
              vim.schedule(function()
                if not accepted then
                  oil.open_float(dir, {}, function()
                    vim.fn.winrestview(view)
                  end)
                end
              end)
            end,
          }
          oil.close()
        end
        require("fzf-lua").files(opts)
      end,
      mode = "n",
      desc = "Find files beneath Oil directory",
    },

    ["g~"] = {
      callback = function()
        set_cwd("tcd")
      end,
      mode = "n",
      desc = "Set tab cwd to Oil directory",
    },
    ["g`"] = {
      callback = function()
        set_cwd("lcd")
      end,
      mode = "n",
      desc = "Set window cwd to Oil directory",
    },

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
    signcolumn = "yes",
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

require("oil-git").setup({
  symbol_position = "signcolumn",
  -- The plugin's default check expects two sign slots. Oil uses one here.
  can_use_signcolumn = function()
    return true
  end,
  show_file_highlights = false,
  show_directory_highlights = false,
  symbols = { file = { added = "A", modified = "M", renamed = "R" } },
})

local map = require("core.keymap")

local function open_oil(layout, file_relative)
  local oil = require("oil")
  local dir = vim.fn.getcwd()
  if file_relative then
    dir = oil.get_current_dir()
      or (vim.api.nvim_buf_get_name(0) ~= "" and vim.fn.expand("%:p:h") or dir)
  end
  if layout == "float" then
    oil.open_float(dir)
  else
    vim.cmd(layout)
    oil.open(dir)
  end
end

map("n", "<leader>ot", function()
  open_oil("tabnew", false)
end, "Oil: open cwd in tab")
map("n", "<leader>of", function()
  open_oil("float", false)
end, "Oil: open cwd in float")
map("n", "<leader>ov", function()
  open_oil("vnew", false)
end, "Oil: open cwd in split vertically")
map("n", "<leader>os", function()
  open_oil("new", false)
end, "Oil: open cwd in split horizontally")

map("n", "<leader>oT", function()
  open_oil("tabnew", true)
end, "Oil: open file directory in tab")
map("n", "<leader>oF", function()
  open_oil("float", true)
end, "Oil: open file directory in float")
map("n", "<leader>oV", function()
  open_oil("vnew", true)
end, "Oil: open file directory in split vertically")
map("n", "<leader>oS", function()
  open_oil("new", true)
end, "Oil: open file directory in split horizontally")
