
local base = require("lsp-base-config")


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

  init_options = {
    lint   = { enable = true, },
    format = { enable = false, },
    semantic_token        = false,  -- else got lagging
    scan_cmake_in_package = true,
  },
}

vim.lsp.enable(name)


--[=====[ base .neocmakelint.toml
line_max_words = 120
command_upcase = "ignore"
enable_external_cmake_lint = false
--]=====]
