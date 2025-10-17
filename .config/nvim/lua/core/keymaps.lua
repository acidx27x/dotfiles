
local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc})
end

-- Key mappings
vim.g.mapleader      = " "  -- Set leader key to space
vim.g.maplocalleader = " "  -- Set local leader key (NEW)

vim.keymap.set({ 'n', 'v' }, "<Space>", "<Nop>", { silent = true })


-- Normal mode mappings
keymap_ns("n", "<leader>nh", ":nohlsearch<CR>", "Clear search highlights")


-- Center screen when jumping
keymap_ns("n", "n", "nzzzv", "Next search result (centered)")
keymap_ns("n", "N", "Nzzzv", "Previous search result (centered)")

keymap_ns("n", "<C-d>", "<C-d>zz", "Half page down (centered)")
keymap_ns("n", "<C-u>", "<C-u>zz", "Half page up (centered)")


-- Delete without yanking
keymap_ns({ "n", "v" }, "<leader>d", '"_d', "Delete without yanking")


-- Buffer navigation
keymap_ns("n", "<leader>bn", ":bnext<CR>", "Next buffer")
keymap_ns("n", "<leader>bp", ":bprevious<CR>", "Previous buffer")


-- Better window navigation
keymap_ns("n", "<A-h>", "<C-w>h", "Move to left window")
keymap_ns("n", "<M-h>", "<C-w>h", "Move to left window")
keymap_ns("n", "<A-j>", "<C-w>j", "Move to bottom window")
keymap_ns("n", "<M-j>", "<C-w>j", "Move to bottom window")
keymap_ns("n", "<A-k>", "<C-w>k", "Move to top window")
keymap_ns("n", "<M-k>", "<C-w>k", "Move to top window")
keymap_ns("n", "<A-l>", "<C-w>l", "Move to right window")
keymap_ns("n", "<M-l>", "<C-w>l", "Move to right window")


-- Splitting & Resizing
keymap_ns("n", "<leader>sv", ":vsplit<CR>", "Split window vertically")
keymap_ns("n", "<leader>sh", ":split<CR>",  "Split window horizontally")

keymap_ns("n", "<A-Up>", ":resize -2<CR>", "Increase window height")
keymap_ns("n", "<M-Up>", ":resize -2<CR>", "Increase window height")

keymap_ns("n", "<A-Down>", ":resize +2<CR>", "Decrease window height")
keymap_ns("n", "<M-Down>", ":resize +2<CR>", "Decrease window height")

keymap_ns("n", "<A-Left>", ":vertical resize +2<CR>", "Decrease window width")
keymap_ns("n", "<M-Left>", ":vertical resize +2<CR>", "Decrease window width")

keymap_ns("n", "<A-Right>", ":vertical resize -2<CR>", "Increase window width")
keymap_ns("n", "<M-Right>", ":vertical resize -2<CR>", "Increase window width")


-- Better indenting in visual mode
-- keymap_ns("v", "<", "<gv", "Indent left and reselect")
-- keymap_ns("v", ">", ">gv", "Indent right and reselect")


-- Better J behavior
keymap_ns("n", "J", "mzJ`z", "Join lines and keep cursor position")



-- Quick config editing
keymap_ns("n", "<leader>rc", function()
  local path = vim.fn.stdpath("config") .. "/init.lua"
  vim.cmd("edit " .. path)
end, "Open nvim config")


-- Copy Full File-Path
keymap_ns("n", "<leader>fp", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("file:", path)
end, "Copy current full file path")




-- terminal
local terminal_state = {
  buf = nil,
  win = nil,
  is_open = false
}

local function FloatingTerminal()
  -- If terminal is already open, close it (toggle behavior)
  if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
    return
  end

  -- Create buffer if it doesn't exist or is invalid
  if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
    terminal_state.buf = vim.api.nvim_create_buf(false, true)
    -- Set buffer options for better terminal experience
    vim.api.nvim_buf_set_option(terminal_state.buf, "bufhidden", "hide")
  end

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create the floating window
  terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
  })

  -- Set transparency for the floating window
  vim.api.nvim_win_set_option(terminal_state.win, "winblend", 0)

  -- Set transparent background for the window
  vim.api.nvim_win_set_option(terminal_state.win, "winhighlight",
    "Normal:Normal,FloatBorder:FloatBorder")

  -- Start terminal if not already running
  local has_terminal = false
  local lines = vim.api.nvim_buf_get_lines(terminal_state.buf, 0, -1, false)
  for _, line in ipairs(lines) do
    if line ~= "" then
      has_terminal = true
      break
    end
  end

  if not has_terminal then
    vim.fn.termopen(os.getenv("SHELL"))
  end

  terminal_state.is_open = true
  vim.cmd("startinsert")

  -- Set up auto-close on buffer leave
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = terminal_state.buf,
    callback = function()
      if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
        vim.api.nvim_win_close(terminal_state.win, false)
        terminal_state.is_open = false
      end
    end,
    once = true
  })
end

-- Function to explicitly close the terminal
local function CloseFloatingTerminal()
  if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
  end
end

-- Key mappings
keymap_ns("n", "<leader>t", FloatingTerminal, "Toggle floating terminal")
keymap_ns("t", "<Esc>", function()
  if terminal_state.is_open then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
  end
end, "Close floating terminal from terminal mode")



-- Function to close buffer but keep tab if its the only buffer in tab
local function smart_close_buffer()
  local buffers_in_tab = #vim.fn.tabpagebuflist()
  if buffers_in_tab > 1 then
    vim.cmd("bdelete")
  else
    -- If its the only buffer in tab, close the tab
    vim.cmd("tabclose")
  end
end

keymap_ns("n", "<leader>bd", smart_close_buffer, "Smart close buffer/tab")

