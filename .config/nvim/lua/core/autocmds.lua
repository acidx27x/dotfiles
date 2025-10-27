
-- Basic autocommands
local augroup = vim.api.nvim_create_augroup("UserConfig", {})


-- Change cwd on enter
-- vim.api.nvim_create_autocmd("VimEnter", {
--   group = augroup,
--   once = true,
--   callback = function()
--     local argv = vim.fn.argv()
--     if #argv > 0 then
--       local target = argv[1]
--       local path = vim.fn.fnamemodify(target, ":p")
--       if path:match("^oil://") then
--         return
--       end
--
--       local dir
--       if vim.fn.isdirectory(path) == 1 then
--         dir = path
--       else
--         dir = vim.fn.fnamemodify(path, ":h")
--       end
--
--       vim.cmd("cd " .. vim.fn.fnameescape(dir))
--     end
--   end,
-- })

vim.api.nvim_create_autocmd("DirChanged", {
  group = augroup,
  callback = function()
    vim.notify(
      "cwd: " .. vim.fn.getcwd(),
      vim.log.levels.INFO,
      { title = "User Autocmd", timeout = 1000, }
    )
  end,
  desc = "DirChanged: notify about cwd",
})


-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank()
  end,
  desc = "TextYankPost: highlight on yank",
})



-- Auto-close terminal when process exits
vim.api.nvim_create_autocmd("TermClose", {
  group = augroup,
  callback = function()
    if vim.v.event.status == 0 then
      vim.api.nvim_buf_delete(0, {})
    end
  end,
  desc = "TermClose: close terminal buffer if process exits",
})


-- Disable line numbers in terminal
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
  desc = "TermOpen: remove extra ui",
})


-- Auto-resize splits when window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
  desc = "VimResized: auto-resize splits when window is resized",
})


-- Save and Load view
vim.api.nvim_create_autocmd("BufWinLeave", {
  group = augroup,
  pattern = "*",
  command = "silent! mkview",
  desc = "BufWinLeave: save view, when closing file",
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup,
  pattern = "*",
  command = "silent! loadview",
  desc = "BufWinEnter: load view, when opening file",
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
  desc = "BufReadPost: return to last edit position",
})

