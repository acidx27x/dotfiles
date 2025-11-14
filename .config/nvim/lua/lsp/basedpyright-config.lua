
local base = require("lsp-base-config")


local name = "basedpyright"
vim.lsp.config[name] = {
  on_init      = base.get_on_init(name),
  on_attach    = base.get_on_attach(name),
  capabilities = base.get_capabilities(name),

  name = name,

  cmd = {
    _G.Paths[name],
    "--stdio",
  },

  settings = {
    basedpyright = {
      analysis = {
        logLevel = "Error",

        inlayHints = {
          genericTypes              = true,
          variableTypes             = true,
          callArgumentNames         = true,
          functionReturnTypes       = true,
          callArgumentNamesMatching = true,
        },

        autoFormatStrings = false,  -- insert f before "" when type {}

        typeCheckingMode       = "all",
        useLibraryCodeForTypes = true,
      },
    },
  },
}

vim.lsp.enable(name, false)

