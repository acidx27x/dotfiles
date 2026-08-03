
vim.lsp.config("*", {
  root_markers = { ".git", },

  single_file_support = true,

  flags = {
    debounce_text_changes  = 150,
    allow_incremental_sync = true,
  },
})
