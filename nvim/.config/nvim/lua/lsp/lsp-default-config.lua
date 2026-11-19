vim.lsp.config("*", {
  root_markers = { ".git" },

  flags = {
    debounce_text_changes = 150,
    allow_incremental_sync = true,
  },
})
