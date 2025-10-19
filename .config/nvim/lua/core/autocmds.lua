
-- Basic autocommands
local augroup = vim.api.nvim_create_augroup("UserConfig", {})


-- Change cwd on enter
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup,
  once = true, -- run only once per nvim start
  callback = function()
    -- Only if Neovim was launched with a file argument
    local argv = vim.fn.argv()
    if #argv > 0 then
      local dir = vim.fn.fnamemodify(argv[1], ":p:h")
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
    end
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = augroup,
  callback = function()
    print("CWD changed to: " .. vim.fn.getcwd())
  end,
})


-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank()
  end,
})



-- Auto-close terminal when process exits
vim.api.nvim_create_autocmd("TermClose", {
  group = augroup,
  callback = function()
    if vim.v.event.status == 0 then
      vim.api.nvim_buf_delete(0, {})
    end
  end,
})


-- Disable line numbers in terminal
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})


-- Auto-resize splits when window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})


-- Create directories when saving files
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function()
    local dir = vim.fn.expand('<afile>:p:h')
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end,
})


-- Save and Load view
vim.api.nvim_create_autocmd({"BufWinLeave"}, {
  group = augroup,
  pattern = '*',
  desc = "Save view, when closing file",
  command = "silent! mkview",
})
vim.api.nvim_create_autocmd({"BufWinEnter"}, {
  group = augroup,
  pattern = '*',
  desc = "Load view, when opening file",
  command = "silent! loadview"
})

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

