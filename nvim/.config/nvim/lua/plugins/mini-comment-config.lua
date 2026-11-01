require("mini.comment").setup({
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
