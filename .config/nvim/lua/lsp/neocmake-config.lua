
local base = require("base-config")


local name = "neocmake"
vim.lsp.config[name] = {
  on_init      = base.get_on_init(name),
  on_attach    = base.get_on_attach(name),
  capabilities = base.get_capabilities(name),

  name = name,

  cmd = {
    _G.Paths[name],
    "--stdio",
  },
}

vim.lsp.enable(name)

