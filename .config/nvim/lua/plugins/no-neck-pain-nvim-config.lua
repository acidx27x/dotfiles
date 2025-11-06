
vim.pack.add({
  { src = "https://github.com/shortcuts/no-neck-pain.nvim" },
})


require("no-neck-pain").setup({
  width = 120,
  buffers = {
    scratchPad = {
      enabled = true,
      fileName = "scratch-notes",
      location = nil,  -- or full path
    },
    bo = {
      filetype = "md",
      fillchars = "eob: ",
    },
  },
})

vim.keymap.set("n", "<leader>np", ":NoNeckPain<CR>",
  { noremap = true, silent = true, desc = "no-neck-pain: toggle", })

