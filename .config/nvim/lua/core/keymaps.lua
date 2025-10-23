
local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
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
--keymap_ns({ "n", "v" }, "<leader>d", '"_d', "Delete without yanking")
keymap_ns({ "n", "v" }, "<leader>d", "<Nop>", "Prevent delete with just 'd'")


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


