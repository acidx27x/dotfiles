
local M = {}


-- common paths
M.paths = {
  -- lsp tools
  ty = "ty",
  clangd = "clangd",
  neocmake = "neocmakelsp",

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
}

-- override paths
-- basically just contains
-- return {
--   name = "path"
-- }
local has_paths_override, paths_override = pcall(require, "paths_override")
if has_paths_override and type(paths_override) == "table" then
  for k, v in pairs(paths_override) do
    M.paths[k] = v
  end
end


_G.Paths = M.paths

return M

