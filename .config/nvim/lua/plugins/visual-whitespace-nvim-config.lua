
vim.pack.add({
  { src = "https://github.com/mcauley-penney/visual-whitespace.nvim" },
})


require("visual-whitespace").setup({
  match_types = {
    space = true,
    tab   = true,
    nbsp  = true,
    lead  = true,
    trail = true,
  },
  list_chars = {
    space = "·",
    lead  = "·",
    trail = "·",
  },
})


vim.keymap.set({ "n", "v" }, "<leader>vw", require("visual-whitespace").toggle, {
  noremap = true, silent  = true,
  desc = "Toggle Visual Whitespace Viewer"
})

