local M = {}

-- common paths
M.paths = {
  -- lsp tools
  ty = "ty",
  clangd = "clangd",
  neocmake = "neocmakelsp",
  basedpyright = "basedpyright-langserver",
  -- linter tools
  ruff = "ruff",

  -- dap tools
  codelldb = "codelldb",
  ["lldb-dap"] = "lldb-dap",

  -- format tools
  gersemi = "gersemi",
  ["clang-format"] = "clang-format",

  -- utils
  ctags = "ctags-universal",
  delta = "delta",
  ["diff-so-fancy"] = "diff-so-fancy",
}

-- override paths
-- basically just contains
-- return {
--   name = "path"
-- }
local has_local_paths, local_paths = pcall(require, "local_paths")
if has_local_paths and type(local_paths) == "table" then
  for k, v in pairs(local_paths) do
    M.paths[k] = v
  end
end

_G.Paths = M.paths

return M
