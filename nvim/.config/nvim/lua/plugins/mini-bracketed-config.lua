require("mini.bracketed").setup({
  comment = { suffix = "/" }, -- Keep [c / ]c for Git hunks.
  window = { suffix = "" }, -- Keep [w / ]w for warnings.
  treesitter = { suffix = "" }, -- Keep [t / ]t for tags.
  indent = { suffix = "" }, -- Keep native include-search keys.
  undo = { suffix = "" }, -- Keep ordinary undo/redo.
})
