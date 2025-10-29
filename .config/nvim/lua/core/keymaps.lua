
local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
end

-- Key mappings
vim.g.mapleader      = " "  -- Set leader key to space
vim.g.maplocalleader = " "  -- Set local leader key (NEW)

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })


-- Normal mode mappings
keymap_ns("n", "<leader>nh", ":nohlsearch<CR>", "hlsearch: clear")


-- Center screen when jumping
keymap_ns("n", "n", "nzzzv", "search: next result (centered)")
keymap_ns("n", "N", "Nzzzv", "search: previous result (centered)")

keymap_ns("n", "<C-d>", "<C-d>zz", "page move: down (centered)")
keymap_ns("n", "<C-u>", "<C-u>zz", "page move: up (centered)")


-- Delete without yanking
--keymap_ns({ "n", "v" }, "<leader>d", '"_d', "edit: delete without yanking")
keymap_ns({ "n", "v" }, "<leader>d", "<Nop>", "edit: prevent delete with just '<leader>d'")
keymap_ns({ "n", "v" }, "<leader>o", "<Nop>", "edit: prevent enter insert with just '<leader>o'")
keymap_ns({ "n", "v" }, "<leader>p", "<Nop>", "edit: prevent enter insert with just '<leader>p'")


-- Buffer navigation
keymap_ns("n", "<leader>bn", ":bnext<CR>", "buffer: next")
keymap_ns("n", "<leader>bp", ":bprevious<CR>", "buffer: previous")


-- Better window navigation
keymap_ns("n", "<A-h>", "<C-w>h", "window: move to left (alt)")
keymap_ns("n", "<M-h>", "<C-w>h", "window: move to left (meta)")
keymap_ns("n", "<A-j>", "<C-w>j", "window: move to bottom (alt)")
keymap_ns("n", "<M-j>", "<C-w>j", "window: move to bottom (meta)")
keymap_ns("n", "<A-k>", "<C-w>k", "window: move to top (alt)")
keymap_ns("n", "<M-k>", "<C-w>k", "window: move to top (meta)")
keymap_ns("n", "<A-l>", "<C-w>l", "window: move to right (alt)")
keymap_ns("n", "<M-l>", "<C-w>l", "window: move to right (meta)")


-- Splitting & Resizing
keymap_ns("n", "<leader>sv", ":vsplit<CR>", "window: split vertically")
keymap_ns("n", "<leader>sh", ":split<CR>",  "window: split horizontally")

keymap_ns("n", "<A-Up>", ":resize +2<CR>", "window: increase height (alt)")
keymap_ns("n", "<M-Up>", ":resize +2<CR>", "window: increase height (meta)")
keymap_ns("n", "<A-Down>", ":resize -2<CR>", "window: decrease height (alt)")
keymap_ns("n", "<M-Down>", ":resize -2<CR>", "window: decrease height (meta)")
keymap_ns("n", "<A-Right>", ":vertical resize +2<CR>", "window: increase width (alt)")
keymap_ns("n", "<M-Right>", ":vertical resize +2<CR>", "window: increase width (meta)")
keymap_ns("n", "<A-Left>", ":vertical resize -2<CR>", "window: decrease width (alt)")
keymap_ns("n", "<M-Left>", ":vertical resize -2<CR>", "window: decrease width (meta)")


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
      { title = "User Keymaps", timeout = 1000, }
    )
  end
end

keymap_ns("n", "<A-w>", function() float_move(-1,  0) end)
keymap_ns("n", "<M-w>", function() float_move(-1,  0) end)
keymap_ns("n", "<A-s>", function() float_move( 1,  0) end)
keymap_ns("n", "<M-s>", function() float_move( 1,  0) end)
keymap_ns("n", "<A-a>", function() float_move( 0, -2) end)
keymap_ns("n", "<M-a>", function() float_move( 0, -2) end)
keymap_ns("n", "<A-d>", function() float_move( 0,  2) end)
keymap_ns("n", "<M-d>", function() float_move( 0,  2) end)


-- Better indenting in visual mode
-- now use mini.move in both modes
-- keymap_ns("v", "<", "<gv", "edit: indent left and reselect")
-- keymap_ns("v", ">", ">gv", "edit: indent right and reselect")


-- Quick config editing
keymap_ns("n", "<leader>rc", function()
  local path = vim.fn.stdpath("config") .. "/init.lua"
  vim.cmd("edit " .. path)
end, "utils: open nvim config")


-- Copy Full File-Path
keymap_ns("n", "<leader>fp", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("file:", path)
end, "utils: copy current full file path")


-- Terminal window
keymap_ns("n", "<leader>tt", ":tabnew | terminal<CR>", "terminal: open in tab")
keymap_ns("n", "<leader>tv", ":vnew | terminal<CR>", "terminal: open in split vertically")
keymap_ns("n", "<leader>th", ":new | terminal<CR>", "terminal: open in split horizontally")


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
keymap_ns("n", "<leader>cd", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  local path = bufname ~= "" and vim.fn.expand("%:p:h") or vim.fn.getcwd()
  if vim.fn.isdirectory(path) == 1 then
    vim.cmd("lcd " .. vim.fn.fnameescape(path))
  else
    vim.notify(
      "<leader>cd: no valid directory found, at '" .. path "'",
      vim.log.levels.WARN,
      { title = "User Keymaps", timeout = 1000, }
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
end, { desc = "editor: show global working directory", })

-- Tab-local CWD
vim.api.nvim_create_user_command("Twd", function()
  local path = vim.fn.getcwd(-1, 0)
  print_workdir("Tab", path)
end, { desc = "editor: show tab-local working directory", })

-- Window-local CWD
vim.api.nvim_create_user_command("Lwd", function()
  local path = vim.fn.getcwd()
  print_workdir("Window", path)
end, { desc = "editor: show window-local working directory", })


-- Better ctags support
vim.api.nvim_create_user_command("CTags", function(opts)
  local args = opts.fargs
  local langs = {}
  local exclude = { "build", "dist", "run", }
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
      { title = "User Keymaps", timeout = 1000, }
    )
    return
  end

  -- Construct the ctags command
  local cmd = { _G.Paths.ctags, "-R", "-f", tagfile, }
  table.insert(cmd, "--languages=" .. table.concat(langs, ","))

  for _, ex in ipairs(exclude) do
    table.insert(cmd, "--exclude=" .. ex)
  end

  table.insert(cmd, ".")  -- better set dir in the end

  -- Run asynchronously
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if not data then return end
      local lines = vim.tbl_filter(function(line)
        return line ~= nil and line ~= ""
      end, data)
      if #lines > 0 then
        vim.notify(
          table.concat(lines, "\n"),
          vim.log.levels.INFO,
          { title = "User Keymaps", timeout = 1000, }
        )
      end
    end,
    on_stderr = function(_, data)
      if not data then return end
      local lines = vim.tbl_filter(function(line)
        return line ~= nil and line ~= ""
      end, data)
      if #lines > 0 then
        vim.notify(
          table.concat(lines, "\n"),
          vim.log.levels.INFO,
          { title = "User Keymaps", timeout = 1000, }
        )
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify(
          "tags generated successfully to '" .. tagfile .. "' file",
          vim.log.levels.INFO,
          { title = "User Keymaps", timeout = 1000, }
        )
      else
        vim.notify(
          "CTags command failed",
          vim.log.levels.ERROR,
          { title = "User Keymaps", timeout = 1000, }
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

