
vim.pack.add({
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/m4xshen/hardtime.nvim" },
})


require("hardtime").setup({
  disable_mouse = false,

  restriction_mode = "block",  -- block or hint
  restricted_keys = {
    ["j"] = false,
    ["k"] = false,
  },
})
