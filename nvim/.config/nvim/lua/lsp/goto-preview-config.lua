require("goto-preview").setup({
  width = 120,
  height = 20,

  focus_on_open = true,

  references = {
    provider = "fzf_lua",
  },

  vim_ui_input = false,
})
