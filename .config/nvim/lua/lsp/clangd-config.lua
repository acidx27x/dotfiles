
local base = require("base-config")


vim.lsp.config.clangd = {
  on_init      = base.get_on_init("clangd"),
  on_attach    = base.get_on_attach("clangd"),
  capabilities = base.get_capabilities("clangd"),

  name = "clangd",
  cmd = {
    "clangd",
    "-j", "4",
    "--pretty",
    "--log=error",
    "--background-index",
    "--pch-storage=memory",
    "--header-insertion=never",
    "--completion-style=detailed",
    "--function-arg-placeholders=0",
    -- "--experimental-modules-support",
  },
  filetypes = {
    "c", "cc", "C", "cpp", "cxx",
    "h", "hh", "H", "hpp", "hxx",
  },
}

vim.lsp.enable("clangd")


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

