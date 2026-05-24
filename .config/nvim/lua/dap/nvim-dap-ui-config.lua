
vim.pack.add({
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
})


require("dapui").setup({
  floating = {
    border = "rounded",
  },
})


local dap, dapui = require("dap"), require("dapui")
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end


vim.keymap.set("n", "<leader>d?", function()
  require("dapui").eval(nil, { enter = true, })
end, { noremap = true, silent = true, desc = "DAP: eval under cursor", })
