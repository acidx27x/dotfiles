

local dap = require("dap")

dap.defaults.fallback.terminal_win_cmd = "tabnew"

dap.set_log_level("WARN")


--
local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
end

keymap_ns("n", "<leader>dtb", dap.toggle_breakpoint, "DAP toggle_breakpoint")
keymap_ns("n", "<leader>dcb", function()
  dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
end, "DAP toggle_breakpoint")
keymap_ns("n", "<leader>dcn", dap.continue,    "DAP continue")
keymap_ns("n", "<leader>dsi", dap.step_into,   "DAP step_into")
keymap_ns("n", "<leader>dso", dap.step_over,   "DAP step_over")
keymap_ns("n", "<leader>dsf", dap.step_out,    "DAP step_out")
keymap_ns("n", "<leader>drp", dap.repl.toggle, "DAP repl toggle")

keymap_ns("n", "<leader>dR", dap.restart, "DAP restart")
--


require("nvim-dap-codelldb-config")
-- require("nvim-dap-lldb-config")
-- require("nvim-dap-cppdbg-config")

