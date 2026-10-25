local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  require("dap.nvim-dap-config")

  -- dap server group
  require("dap.nvim-dap-codelldb-config")
  --

  -- dap ui group
  require("dap.nvim-dap-ui-config")

  require("dap.nvim-dap-virtual-text-config")
  --
end

local dap_actions = {
  b = { "toggle_breakpoint", "DAP: toggle breakpoint" },
  c = { "continue", "DAP: continue" },
  n = { "step_over", "DAP: step over" },
  s = { "step_into", "DAP: step into" },
  o = { "step_out", "DAP: step out" },
  R = { "restart", "DAP: restart" },
}
for suffix, action in pairs(dap_actions) do
  lazy.keymap("n", "<leader>d" .. suffix, "dap", "dap.config", function()
    require("dap")[action[1]]()
  end, action[2])
end
lazy.keymap("n", "<leader>dB", "dap", "dap.config", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, "DAP: set conditional breakpoint")
lazy.keymap("n", "<leader>dt", "dap", "dap.config", function()
  require("dap").repl.toggle()
end, "DAP: toggle REPL")
lazy.keymap("n", "<leader>d?", "dap", "dap.config", function()
  require("dapui").eval(nil, { enter = true })
end, "DAP: evaluate under cursor")

return M
