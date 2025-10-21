
require("dap").adapters.codelldb = {
  type    = "executable",
  command = "codelldb",
  args = {},
  options = {
    env = {},
  },
}
-- require("dap").adapters.codelldb = {
--   name    = "codelldb",
--   type    = "server",
--   port    = "${port}",
--   executable = {
--     command = "C:\\tools\\LLVM\\codelldb-win32-x64\\extension\\adapter\\codelldb.exe",
--     args = { "--port", "${port}" },
--     detached = vim.loop.os_uname().sysname ~= "Windows",
--   },
-- }


local launch = {
  name    = "CodeLLDB: Launch file",
  type    = "codelldb",
  request = "launch",

  program = "${command:pickFile}",
  args    = {},  -- TODO get input from user
  cwd     = "${workspaceFolder}",
  preRunCommands = { "breakpoint set --name main", },

  console = "integratedTerminal",
}

local attach = {
  name    = "CodeLLDB: Attach process",
  type    = "codelldb",
  request = "attach",

  program = "${command:pickProcess}",
  args    = {},  -- TODO get input from user
  cwd     = "${workspaceFolder}",
  waitFor = true,

  console = "integratedTerminal",
}


require("dap").configurations.c   = { launch, attach, }
require("dap").configurations.cpp = { launch, attach, }


