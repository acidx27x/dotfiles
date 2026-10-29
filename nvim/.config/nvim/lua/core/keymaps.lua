local map = require("core.keymap")

-- Key mappings
vim.g.mapleader = " " -- Set leader key to space
vim.g.maplocalleader = " " -- Set local leader key (NEW)
local alt_modifier = vim.uv.os_uname().sysname == "Darwin" and "M" or "A"

map({ "n", "v" }, "<Space>", "<Nop>", "leader prefix")

-- Normal mode mappings
map("n", "<leader>nh", ":nohlsearch<CR>", "hlsearch: clear")

-- Center screen when jumping
map("n", "n", "nzzzv", "search: next result (centered)")
map("n", "N", "Nzzzv", "search: previous result (centered)")

map("n", "<C-d>", "<C-d>zz", "page move: down (centered)")
map("n", "<C-u>", "<C-u>zz", "page move: up (centered)")

-- Delete without yanking
--map({ "n", "v" }, "<leader>d", '"_d', "edit: delete without yanking")
map({ "n", "v" }, "<leader>d", "<Nop>", "edit: prevent delete with just '<leader>d'")
map({ "n", "v" }, "<leader>o", "<Nop>", "edit: prevent enter insert with just '<leader>o'")
map({ "n", "v" }, "<leader>p", "<Nop>", "edit: prevent enter insert with just '<leader>p'")

-- Buffer navigation
map("n", "<leader>bd", function()
  require("mini.bufremove").delete(0, false)
end, "buffer: delete and preserve layout")
map("n", "<leader>bn", ":bnext<CR>", "buffer: next")
map("n", "<leader>bp", ":bprevious<CR>", "buffer: previous")
map("n", "]b", ":bnext<CR>", "buffer: next")
map("n", "[b", ":bprevious<CR>", "buffer: previous")
map("n", "<leader>bb", "<C-^>", "buffer: alternate")

-- Better window navigation
map("n", "<leader>q", ":close<CR>", "window: close")
map("n", "<leader>Q", ":quit<CR>", "window: quit")

map("n", ("<%s-h>"):format(alt_modifier), "<C-w>h", "window: move to left (alt/meta)")
map("n", ("<%s-j>"):format(alt_modifier), "<C-w>j", "window: move to bottom (alt/meta)")
map("n", ("<%s-k>"):format(alt_modifier), "<C-w>k", "window: move to top (alt/meta)")
map("n", ("<%s-l>"):format(alt_modifier), "<C-w>l", "window: move to right (alt/meta)")

-- Splitting & Resizing
map("n", "<leader>sv", ":vsplit<CR>", "window: split vertically")
map("n", "<leader>sh", ":split<CR>", "window: split horizontally")

local function normal_window_count()
  local count = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      count = count + 1
    end
  end
  return count
end

map("n", "<leader>st", function()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    vim.cmd("tab split")
    vim.api.nvim_win_close(win, true)
  elseif normal_window_count() > 1 then
    vim.cmd("wincmd T")
  else
    vim.cmd("tab split")
  end
end, "window: move to new tab")

map("n", "<leader>sf", function()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    for _, target in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(target).relative == "" then
        vim.api.nvim_win_set_config(win, { split = "right", win = target })
        return
      end
    end
  end

  local width = math.max(1, math.floor(vim.o.columns * 0.8))
  local height = math.max(1, math.floor(vim.o.lines * 0.7))
  local config = {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
  }
  if normal_window_count() == 1 then
    vim.api.nvim_open_win(vim.api.nvim_win_get_buf(win), true, config)
  else
    vim.api.nvim_win_set_config(win, config)
  end
end, "window: toggle float or split")

map("n", "<leader>sH", "<C-w>H", "window: move split left")
map("n", "<leader>sJ", "<C-w>J", "window: move split bottom")
map("n", "<leader>sK", "<C-w>K", "window: move split top")
map("n", "<leader>sL", "<C-w>L", "window: move split right")
map("n", "<leader>sx", "<C-w>x", "window: exchange splits")
map("n", "<leader>s=", "<C-w>=", "window: equalize splits")

map("n", ("<%s-Up>"):format(alt_modifier), ":resize +2<CR>", "window: increase height (alt/meta)")
map("n", ("<%s-Down>"):format(alt_modifier), ":resize -2<CR>", "window: decrease height (alt/meta)")
map(
  "n",
  ("<%s-Right>"):format(alt_modifier),
  ":vertical resize +2<CR>",
  "window: increase width (alt/meta)"
)
map(
  "n",
  ("<%s-Left>"):format(alt_modifier),
  ":vertical resize -2<CR>",
  "window: decrease width (alt/meta)"
)

-- Move focused floating windows
local function float_move(drow, dcol)
  local win = vim.api.nvim_get_current_win()
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    cfg.row = cfg.row + drow
    cfg.col = cfg.col + dcol
    vim.api.nvim_win_set_config(win, cfg)
  else
    vim.notify(
      "this keymap is used for moving focused floating window",
      vim.log.levels.WARN,
      { title = "User Keymaps", timeout = 1000 }
    )
  end
end

map("n", ("<%s-w>"):format(alt_modifier), function()
  float_move(-1, 0)
end, "window: move floating window up")
map("n", ("<%s-s>"):format(alt_modifier), function()
  float_move(1, 0)
end, "window: move floating window down")
map("n", ("<%s-a>"):format(alt_modifier), function()
  float_move(0, -2)
end, "window: move floating window left")
map("n", ("<%s-d>"):format(alt_modifier), function()
  float_move(0, 2)
end, "window: move floating window right")

-- Better indenting in visual mode
-- now use mini.move in both modes
-- map("v", "<", "<gv", "edit: indent left and reselect")
-- map("v", ">", ">gv", "edit: indent right and reselect")

-- Quick config editing
map("n", "<leader>rc", function()
  local path = vim.fn.stdpath("config") .. "/init.lua"
  vim.cmd("edit " .. path)
end, "utils: open nvim config")

-- Copy Full File-Path
map("n", "<leader>fp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("file:", path)
end, "utils: copy current full file path")

-- Terminal window
map("n", "<leader>tt", ":tabnew | terminal<CR>", "terminal: open in tab")
map("n", "<leader>tv", ":vnew | terminal<CR>", "terminal: open in split vertically")
map("n", "<leader>th", ":new | terminal<CR>", "terminal: open in split horizontally")

-- Open buffer in tab with number
vim.api.nvim_create_user_command("BTab", function(opts)
  local bufnum = tonumber(opts.args)
  if not bufnum then
    print("Usage: :BTab <buffer-number>")
    return
  end

  local bufname = vim.fn.bufname(bufnum)
  if bufname == "" then
    print("Invalid buffer number: " .. bufnum)
    return
  end

  vim.cmd("tabedit " .. vim.fn.fnameescape(bufname))
end, {
  nargs = 1,
  complete = "buffer",
  desc = "cmdline: open buffer by number in a tab",
})
vim.cmd("cabbrev btab BTab")

-- Better cd -> lcd
map("n", "<leader>cd", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  local path = bufname ~= "" and vim.fn.expand("%:p:h") or vim.fn.getcwd()
  if vim.fn.isdirectory(path) == 1 then
    vim.cmd("lcd " .. vim.fn.fnameescape(path))
  else
    vim.notify(
      "<leader>cd: no valid directory found, at '" .. path .. "'",
      vim.log.levels.WARN,
      { title = "User Keymaps", timeout = 1000 }
    )
  end
end, "buffer: change local cwd to current buffer's directory")

-- Better pwd info
local function print_workdir(scope, path)
  if path == "" then
    print(scope .. ": [none]")
  else
    print(scope .. ": " .. path)
  end
end

-- Global CWD
vim.api.nvim_create_user_command("Cwd", function()
  local path = vim.fn.getcwd(-1, -1)
  print_workdir("Global", path)
end, { desc = "editor: show global working directory" })

-- Tab-local CWD
vim.api.nvim_create_user_command("Twd", function()
  local path = vim.fn.getcwd(-1, 0)
  print_workdir("Tab", path)
end, { desc = "editor: show tab-local working directory" })

-- Window-local CWD
vim.api.nvim_create_user_command("Lwd", function()
  local path = vim.fn.getcwd()
  print_workdir("Window", path)
end, { desc = "editor: show window-local working directory" })

-- Better ctags support
vim.api.nvim_create_user_command("CTags", function(opts)
  local executable = require("core.tools").ensure_executable(
    "ctags",
    { "ctags-universal", "ctags" },
    "CTags"
  )
  if not executable then
    return
  end
  local args = opts.fargs
  local langs = {}
  local exclude = { "build", "dist", "run" }
  local tagfile = ".tags"

  -- Parse arguments
  for _, arg in ipairs(args) do
    local key, val = arg:match("(%w+)=([%w%+]+)")
    if key == "lang" then
      table.insert(langs, val)
    elseif key == "exclude" then
      table.insert(exclude, val)
    end
  end

  if #langs == 0 then
    vim.notify(
      "no languages provided. use :CTags lang=<language>",
      vim.log.levels.ERROR,
      { title = "User Keymaps", timeout = 1000 }
    )
    return
  end

  -- Construct the ctags command
  local cmd = { executable, "-R", "-f", tagfile }
  table.insert(cmd, "--languages=" .. table.concat(langs, ","))

  for _, ex in ipairs(exclude) do
    table.insert(cmd, "--exclude=" .. ex)
  end

  table.insert(cmd, ".") -- better set dir in the end

  -- Run asynchronously
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if not data then
        return
      end
      local lines = vim.tbl_filter(function(line)
        return line ~= nil and line ~= ""
      end, data)
      if #lines > 0 then
        vim.notify(
          table.concat(lines, "\n"),
          vim.log.levels.INFO,
          { title = "User Keymaps", timeout = 1000 }
        )
      end
    end,
    on_stderr = function(_, data)
      if not data then
        return
      end
      local lines = vim.tbl_filter(function(line)
        return line ~= nil and line ~= ""
      end, data)
      if #lines > 0 then
        vim.notify(
          table.concat(lines, "\n"),
          vim.log.levels.INFO,
          { title = "User Keymaps", timeout = 1000 }
        )
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify(
          "tags generated successfully to '" .. tagfile .. "' file",
          vim.log.levels.INFO,
          { title = "User Keymaps", timeout = 1000 }
        )
      else
        vim.notify(
          "CTags command failed",
          vim.log.levels.ERROR,
          { title = "User Keymaps", timeout = 1000 }
        )
      end
    end,
  })
end, {
  nargs = "*",
  complete = function(_, _, _)
    return {
      "lang=CMake",
      "exclude=build",
    }
  end,
  desc = "utils: create ctags with provided languages and exclude dirs",
})
