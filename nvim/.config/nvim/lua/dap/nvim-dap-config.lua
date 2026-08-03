
vim.pack.add({
  { src = "https://github.com/mfussenegger/nvim-dap" },
})


local dap = require("dap")

dap.defaults.fallback.terminal_win_cmd = "tabnew"

dap.set_log_level("WARN")


local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
end

keymap_ns("n", "<leader>db", dap.toggle_breakpoint, "DAP: toggle_breakpoint")
keymap_ns("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, "DAP: set_breakpoint condition")
keymap_ns("n", "<leader>dc", dap.continue,    "DAP: continue")
keymap_ns("n", "<leader>ds", dap.step_into,   "DAP: step_into")
keymap_ns("n", "<leader>dn", dap.step_over,   "DAP: step_over")
keymap_ns("n", "<leader>do", dap.step_out,    "DAP: step_out")
keymap_ns("n", "<leader>dt", dap.repl.toggle, "DAP: repl toggle")

keymap_ns("n", "<leader>dR", dap.restart, "DAP: restart")
