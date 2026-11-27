local comment = require("mini.comment")

comment.setup({
  options = {
    start_of_line = false,
    pad_comment_parts = true,
  },

  mappings = {
    comment = "gc",
    comment_visual = "gc",
    comment_line = "gcc",

    textobject = "gc",
  },
})

vim.keymap.set("x", "gc", function()
  local operator = comment.operator()
  if operator == "" then
    return
  end
  vim.cmd.normal({ operator, bang = true })
  vim.api.nvim_win_set_cursor(0, { vim.fn.line("'["), 0 })
  vim.cmd.normal({ "V", bang = true })
  vim.api.nvim_win_set_cursor(0, { vim.fn.line("']"), 0 })
end, { silent = true, desc = "Comment selection" })
