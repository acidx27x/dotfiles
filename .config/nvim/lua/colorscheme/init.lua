
-- colorscheme group
vim.pack.add({
  { src = "https://github.com/vague-theme/vague.nvim" },
  { src = "https://github.com/rebelot/kanagawa.nvim" },
})


require("vague-nvim-config")
require("kanagawa-nvim-config")


--vim.cmd("colorscheme vague")
vim.cmd.colorscheme("kanagawa")
--


--vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
--vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
--vim.api.nvim_set_hl(0, "SignColumn",  { bg = "none" })
--vim.api.nvim_set_hl(0, "WinBarNC",    { bg = "none" })
--vim.api.nvim_set_hl(0, "WinBar",      { bg = "none" })
--vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

