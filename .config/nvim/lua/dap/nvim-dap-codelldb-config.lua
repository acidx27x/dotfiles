
-- use name as 'lldb' to be able to have same config for vscode
require("dap").adapters.lldb = {
  type    = "executable",
  command = _G.Paths.codelldb,  -- may need adjust full path
  args    = {},
  options = {
    env = {},
  },
}
-- require("dap").adapters.lldb = {
--   type    = "server",
--   port    = "${port}",
--   executable = {
--     command = _G.Paths.codelldb,  -- may need adjust full path
--     args = { "--port", "${port}" },
--     detached = vim.loop.os_uname().sysname ~= "Windows",
--   },
-- }


local launch = {
  name    = "CodeLLDB: Launch file",
  type    = "lldb",
  request = "launch",

  program = "${command:pickFile}",
  args    = {},  -- TODO get input from user
  cwd     = "${workspaceFolder}",
  preRunCommands = { "breakpoint set --name main", },
}

local attach = {
  name    = "CodeLLDB: Attach process",
  type    = "lldb",
  request = "attach",

  program = "${command:pickProcess}",
  args    = {},  -- TODO get input from user
  cwd     = "${workspaceFolder}",
  waitFor = true,
}


require("dap").configurations.c   = { launch, attach, }
require("dap").configurations.cpp = { launch, attach, }


-- base launch json
-- {
--     "version": "0.2.0",
--     "configurations": [
--         {
--             "type": "lldb",
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
