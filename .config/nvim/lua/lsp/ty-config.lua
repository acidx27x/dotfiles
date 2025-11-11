
local base = require("lsp-base-config")


local name = "ty"
vim.lsp.config[name] = {
  on_init      = base.get_on_init(name),
  on_attach    = base.get_on_attach(name),
  capabilities = base.get_capabilities(name),

  name = name,

  cmd = {
    _G.Paths[name],
    "server",
  },

  init_options = {
    logLevel = "error",
  },

  settings = {
    ty = {
      experimental = {
        rename = true,
      },
    },
  },
}

vim.lsp.enable(name)

