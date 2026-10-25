local dap = require("dap")

dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = _G.Paths.codelldb,
    args = { "--port", "${port}" },
    detached = vim.uv.os_uname().sysname ~= "Windows_NT",
  },
}

local launch = {
  name = "CodeLLDB: Launch file",
  type = "codelldb",
  request = "launch",

  program = "${command:pickFile}",
  args = {}, -- TODO get input from user
  cwd = "${workspaceFolder}",
  preRunCommands = { "breakpoint set --name main" },
}

local attach = {
  name = "CodeLLDB: Attach process",
  type = "codelldb",
  request = "attach",

  program = "${command:pickProcess}",
  args = {}, -- TODO get input from user
  cwd = "${workspaceFolder}",
  waitFor = true,
}

dap.configurations.c = { launch, attach }
dap.configurations.cpp = { launch, attach }

-- base launch json
-- {
--     "version": "0.2.0",
--     "configurations": [
--         {
--             "type": "codelldb",
--             "request": "launch",
--             "name": "test_name",
--             "program": "path/to/file",
--             "args": [],
--             "preRunCommands": ["breakpoint set --name main"],
--             "cwd": "${workspaceFolder}",
--             "console": "integratedTerminal"
--         }
--     ]
-- }
--
