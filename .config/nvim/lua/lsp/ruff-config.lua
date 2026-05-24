
local base = require("lsp-base-config")


local name = "ruff"

local on_attach = function(client, bufnr)
  if client.name == name then
    -- disable hover in favor of other lsp
    client.server_capabilities.hoverProvider = false
  end
end

vim.lsp.config[name] = {
  on_init      = base.get_on_init(name),
  on_attach    = base.get_on_attach(name, on_attach),
  capabilities = base.get_capabilities(name),

  name = name,

  cmd = {
    _G.Paths[name],
    "server",
  },

  init_options = {
    settings = {
      logLevel = "error",

      fixAll                  = false,  -- do not use fixAll code action
      showSyntaxErrors        = false,  -- use other lsp for it
      configurationPreference = "filesystemFirst",

      lint = {
        preview = true,
        select = {
          "F",   -- Pyflakes rules
          "W",   -- PyCodeStyle warnings
          "E",   -- PyCodeStyle errors
          "I",   -- Sort imports properly
          "UP",  -- Warn if certain things can changed due to newer Python versions
          "C4",  -- Catch incorrect use of comprehensions, dict, list, etc
          "FA",  -- Enforce from __future__ import annotations
          "ISC", -- Good use of string concatenation
          "ICN", -- Use common import conventions
          "RET", -- Good return practices
          "SIM", -- Common simplification rules
          "TID", -- Some good import practices
          "TC",  -- Enforce importing certain types in a TYPE_CHECKING block
          "PTH", -- Use pathlib instead of os.path
          "TD",  -- Be diligent with TODO comments
          "NPY", -- Some numpy-specific things
          "A",   -- detect shadowed builtins
          "BLE", -- disallow catch-all exceptions
          "S",   -- disallow things like "exec"; also restricts "assert" but I just NOQA it when
          "COM", -- enforce trailing comma rules
          "DTZ", -- require strict timezone manipulation with datetime
          "FBT", -- detect boolean traps
          "N",   -- enforce naming conventions, e.g. ClassName vs function_name
        },
      },
    },
  },
}

vim.lsp.enable(name)
