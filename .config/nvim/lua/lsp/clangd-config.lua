
local base = require("base-config")


base.setup()

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
    "c", "c.in",
    "cc", "cc.in",
    "C", "C.in",
    "cpp", "cpp.in",
    "cxx", "cxx.in",
    "h", "h.in",
    "hh", "hh.in",
    "hpp", "hpp.in",
    "hxx", "hxx.in",
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

