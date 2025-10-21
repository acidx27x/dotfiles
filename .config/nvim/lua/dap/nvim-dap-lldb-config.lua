
require("dap").adapters.lldb = {
  name    = "lldb",
  type    = "executable",
  command = "lldb-dap",  -- adjust full path
}
-- require("dap").adapters.lldb = {
--   name    = "lldb",
--   type    = "server",
--   port    = "${port}",
--   executable = {
--     command = "lldb-dap",
--     args = { "--port", "${port}" },
--     detached = vim.loop.os_uname().sysname ~= "Windows",
--   },
-- }


local launch = {
  name    = "LLDB: Launch file",
  type    = "lldb",
  request = "launch",

  program = "${command:pickFile}",
  args    = {},  -- TODO get input from user
  cwd     = "${workspaceFolder}",
  preRunCommands = { "breakpoint set --name main", },

  console = "integratedTerminal",
}

local attach = {
  name    = "LLDB: Attach process",
  type    = "lldb",
  request = "attach",

  program = "${command:pickProcess}",
  args    = {},  -- TODO get input from user
  cwd     = "${workspaceFolder}",
  waitFor = true,

  console = "integratedTerminal",
}


require("dap").configurations.c   = { launch, attach, }
require("dap").configurations.cpp = { launch, attach, }

