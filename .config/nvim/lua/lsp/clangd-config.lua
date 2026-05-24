
local base = require("lsp-base-config")


local name = "clangd"
vim.lsp.config[name] = {
  on_init      = base.get_on_init(name),
  on_attach    = base.get_on_attach(name),
  capabilities = base.get_capabilities(name),

  name = name,
  cmd = {
    _G.Paths[name],
    "-j", "8",
    "--pretty",
    "--log=error",
    "--clang-tidy",
    "--background-index",
    "--pch-storage=disk",
    "--header-insertion=never",
    "--completion-style=detailed",
    "--function-arg-placeholders=0",
    -- "--experimental-modules-support",
  },
}

vim.lsp.enable(name)


--[=====[ base .clangd
CompileFlags:  # ignore some gcc unsupported flags
  Remove: [-f*]
  CompilationDatabase: Ancestors
  BuiltinHeaders: QueryDriver

Index:
  Background: Build
  StandardLibrary: Yes

Diagnostics:
  UnusedIncludes: Strict

Completion:
  ArgumentLists: None
  HeaderInsertion: Never
  CodePatterns: None

InlayHints:  # other are true by default
  Enabled: Yes
  DefaultArguments: Yes
  BlockEnd: Yes

Hover:
  ShowAKA: Yes

Documentation:
  CommentFormat: Doxygen  # md + doxygen
--]=====]
