local base = require("lsp.lsp-base-config")

local name = "neocmake"
local capabilities = base.get_capabilities(name)
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

vim.lsp.config[name] = {
  on_init = base.get_on_init(name),
  on_attach = base.get_on_attach(name),
  capabilities = capabilities,

  name = name,

  cmd = {
    _G.Paths[name],
    "stdio",
  },

  init_options = {
    format = { enable = false },
    lint = { enable = true },
    semantic_token = false, -- else got lagging
    scan_cmake_in_package = true,
    use_snippets = true,
  },
}

base.enable(name, { "cmake" })

--[=====[ base .neocmake.toml
line_max_words = 120
command_upcase = "ignore"
enable_external_cmake_lint = false

[included_cmakes]
files = ["global/config.cmake"]
glob_rules = ["global/*.cmake"]
--]=====]
