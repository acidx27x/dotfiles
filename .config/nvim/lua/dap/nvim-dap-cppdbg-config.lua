
-- TODO
-- https://github.com/microsoft/vscode-cpptools/releases/
require("dap").adapters.cppdbg = {
  type    = "executable",
  command = "OpenDebugAD7",
  args    = {},
  options = {
    env = {},
  },
}
