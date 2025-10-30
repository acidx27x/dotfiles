
local base = require("base-config")


local name = "ruff"
vim.lsp.config[name] = {
  on_init      = base.get_on_init(name),
  on_attach    = base.get_on_attach(name),
  capabilities = base.get_capabilities(name),

  name = name,

  cmd = {
    _G.Paths[name],
    "server",
  },

  single_file_support = true,
}

vim.lsp.enable(name)

