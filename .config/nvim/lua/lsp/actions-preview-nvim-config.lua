
vim.pack.add({
  { src = "https://github.com/aznhe21/actions-preview.nvim" },
})


require("actions-preview").setup({
  diff = {
    algorithm = "patience",
    ignore_whitespace = true,
  },

  highlight_command = {
    -- require("actions-preview.highlight").delta(_G.Paths.delta .. " --no-gitconfig --side-by-side --dark"),
    require("actions-preview.highlight").diff_so_fancy(_G.Paths["diff-so-fancy"]),
  },

  backend = { "minipick", },
})

