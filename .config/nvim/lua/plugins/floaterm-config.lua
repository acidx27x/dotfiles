
vim.pack.add({
  { src = "https://github.com/nvzone/volt" },
  { src = "https://github.com/nvzone/floaterm" },
})


require("floaterm").setup({
  terminals = {
    { name = "Terminal" },
    -- cmd can be function too
    -- { name = "Terminal", cmd = "neofetch" },
  },
})


vim.keymap.set("n", "<leader>tf", require("floaterm").toggle,
  { noremap = true, silent = true, desc = "floaterm: toggle float window", })

