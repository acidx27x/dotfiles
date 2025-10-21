
vim.pack.add({
  { src = "https://github.com/mfussenegger/nvim-dap" },
})
require("nvim-dap-config")

vim.pack.add({
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
})
require("nvim-dap-virtual-text-config")


vim.pack.add({
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
})
require("nvim-dap-ui-config")

