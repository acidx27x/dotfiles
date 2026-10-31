local map = require("core.keymap")
local M = {}

local function clangd_only(client)
  return client.name == "clangd"
end

local function without_neocmake(client)
  return client.name ~= "neocmake"
end

local function without_ruff(client)
  return client.name ~= "ruff"
end

local function lsp_client_only(name)
  return function(client)
    return client.name == name
  end
end

-- Set global formatter choices in `defaults` and formatter commands in M.setup().
-- To override a project, put `.nvim.json` in its root or an ancestor directory:
-- {
--   "formatting": {
--     "format_on_save": false,
--     "filetypes": {
--       "cpp": { "formatters": ["clang-format"], "lsp_format": "never" }
--     }
--   }
-- }
-- <leader>cf formats manually even when format_on_save is false.
-- Each key below is a Neovim filetype; quoted entries name Conform formatters.
-- Add or replace formatter names here, and set their command paths in M.setup().
-- lsp_format = "prefer" tries an allowed LSP formatter before the external tool;
-- "fallback" is the default, and "never" disables LSP formatting for that filetype.
-- filter receives an LSP client: clangd_only allows clangd, while the other
-- filters exclude neocmake and ruff. Omit filter to allow any LSP client.
local defaults = {
  lua = { "stylua" },
  c = { "clang-format", lsp_format = "prefer", filter = clangd_only },
  cpp = { "clang-format", lsp_format = "prefer", filter = clangd_only },
  cmake = {
    "gersemi",
    filter = without_neocmake,
  },
  python = {
    "ruff_format",
    filter = without_ruff,
  },
}

local function settings(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return {}
  end
  local path = vim.fs.find(".nvim.json", { path = vim.fs.dirname(filename), upward = true })[1]
  if not path then
    return {}
  end

  local ok, config = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  if not ok or type(config) ~= "table" then
    vim.notify_once("Invalid project settings: " .. path, vim.log.levels.WARN)
    return {}
  end
  return type(config.formatting) == "table" and config.formatting or {}
end

local function policy(bufnr, filetype)
  local configured = vim.deepcopy(defaults[filetype] or {})
  local filetypes = settings(bufnr).filetypes
  if type(filetypes) ~= "table" then
    return configured
  end
  local override = filetypes[vim.bo[bufnr].filetype] or filetypes[filetype]
  if type(override) ~= "table" then
    return configured
  end

  if override.formatters ~= nil then
    for i = #configured, 1, -1 do
      configured[i] = nil
    end
    vim.list_extend(configured, override.formatters)
  end
  if override.lsp_format then
    configured.lsp_format = override.lsp_format
  end
  if override.lsp_client then
    configured.filter = lsp_client_only(override.lsp_client)
  end
  return configured
end

function M.setup()
  local formatters_by_ft = {}
  for ft in pairs(defaults) do
    local filetype = ft
    formatters_by_ft[filetype] = function(bufnr)
      return policy(bufnr, filetype)
    end
  end
  formatters_by_ft["_"] = function(bufnr)
    return policy(bufnr, vim.bo[bufnr].filetype)
  end

  require("conform").setup({
    formatters_by_ft = formatters_by_ft,
    formatters = {
      ["clang-format"] = { command = _G.Paths["clang-format"] },
      gersemi = { command = _G.Paths.gersemi },
      ruff_format = { command = _G.Paths.ruff },
    },
    default_format_opts = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
    format_on_save = function(bufnr)
      if vim.b[bufnr].autosave_writing or settings(bufnr).format_on_save == false then
        return
      end
      return {}
    end,
    log_level = vim.log.levels.WARN,
  })
end

map({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = false })
end, "format: buffer or selection")

return M
