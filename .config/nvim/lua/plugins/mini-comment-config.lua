
require("mini.comment").setup({
  options = {
    start_of_line = false,
    pad_comment_parts = true,
  },

  mappings = {
    comment        = "<leader>cc",
    comment_visual = "<leader>cc",
    comment_line   = "<leader>ccl",

    textobject = "<leader>cc",
  },
})

