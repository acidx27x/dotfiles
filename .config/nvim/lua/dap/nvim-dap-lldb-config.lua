
-- use name as 'lldb-dap' to be able to have same config for vscode
require("dap").adapters["lldb-dap"] = {
  type    = "executable",
  command = _G.Paths["lldb-dap"],  -- may need adjust full path
  args    = {},
  options = {
    env = {},
  },
}


local launch = {
  name    = "LLDB: Launch file",
  type    = "lldb-dap",
  request = "launch",

  program = "${command:pickFile}",
  args    = {},  -- TODO get input from user
  cwd     = "${workspaceFolder}",
  preRunCommands = { "breakpoint set --name main", },
}

local attach = {
  name    = "LLDB: Attach process",
  type    = "lldb-dap",
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
--             "type": "lldb-dap",
--             "request": "launch",
--             "name": "test_name",
--             "program": "path/to/file",
--             "args": [],
--             "preRunCommands": ["breakpoint set --name main"],
--             "cwd": "${workspaceFolder}"
--         }
--     ]
-- }
-- looks like doenst support "console": "integratedTerminal" on windows, got strange error on it
