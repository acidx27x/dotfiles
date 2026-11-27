local map = require("core.keymap")
local M = {}

local function clangd_only(client)
  return client.name == "clangd"
end

local function without_neocmake(client)
  return client.name ~= "neocmake"
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
--       "cpp": { "format_on_save": true, "formatters": ["clang-format"], "lsp_format": "never" }
--     }
--   }
-- }
-- <leader>cf formats manually even when format_on_save is false.
-- Each key below is a Neovim filetype; quoted entries name Conform formatters.
-- Add or replace formatter names here, and set their command paths in M.setup().
-- lsp_format = "prefer" tries an allowed LSP formatter before the external tool;
-- "fallback" is the default, and "never" disables LSP formatting for that filetype.
-- filter receives an LSP client: clangd_only allows clangd, while
-- without_neocmake excludes neocmake. Omit filter to allow any LSP client.
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
    lsp_format = "prefer",
    filter = lsp_client_only("ruff"),
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
      gersemi = {
        command = _G.Paths.gersemi,
        range_args = function(_, ctx)
          return {
            "--quiet",
            "--line-ranges",
            string.format("%d-%d", ctx.range.start[1], ctx.range["end"][1]),
            "-",
          }
        end,
      },
      ruff_format = { command = _G.Paths.ruff },
    },
    default_format_opts = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
    format_on_save = function(bufnr)
      if vim.b[bufnr].autosave_writing then
        return
      end
      local config = settings(bufnr)
      local format_on_save = config.format_on_save
      local override = type(config.filetypes) == "table"
        and config.filetypes[vim.bo[bufnr].filetype]
      if type(override) == "table" and override.format_on_save ~= nil then
        format_on_save = override.format_on_save
      end
      if format_on_save == false then
        return
      end
      return {}
    end,
    log_level = vim.log.levels.WARN,
  })
end

local selection_ns = vim.api.nvim_create_namespace("conform-visual-selection")

map({ "n", "v" }, "<leader>cf", function()
  local conform = require("conform")
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then
    conform.format({ async = false })
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local anchor, cursor = vim.fn.getpos("v"), vim.fn.getpos(".")
  local start_row, start_col = math.min(anchor[2], cursor[2]) - 1, 0
  local end_row, end_col = math.max(anchor[2], cursor[2]), 0
  if mode == "v" then
    local region = vim.fn.getregionpos(anchor, cursor, { type = mode })
    local first, last = region[1][1], region[#region][2]
    start_row, start_col = first[2] - 1, first[3] - 1
    end_row, end_col = last[2] - 1, last[3]
  end

  -- Track both sides of the selection, including text inserted at the boundaries.
  local mark = vim.api.nvim_buf_set_extmark(buf, selection_ns, start_row, start_col, {
    end_row = end_row,
    end_col = end_col,
    right_gravity = false,
    end_right_gravity = true,
  })
  conform.format({ async = false }, function(_, did_edit)
    local row, col, bounds =
      unpack(vim.api.nvim_buf_get_extmark_by_id(buf, selection_ns, mark, { details = true }))
    vim.api.nvim_buf_del_extmark(buf, selection_ns, mark)
    if not did_edit then
      return
    end

    local last_row, last_col = bounds.end_row, bounds.end_col
    if row == last_row and col == last_col then
      vim.cmd.normal({ "\27", bang = true })
      return
    end
    if mode == "V" then
      last_row = last_col == 0 and last_row - 1 or last_row
      last_col = 0
    elseif vim.o.selection ~= "exclusive" then
      if last_col == 0 then
        last_row = last_row - 1
        last_col = #vim.fn.getline(last_row + 1)
      else
        local line = vim.fn.getline(last_row + 1)
        last_col = vim.fn.byteidx(line, vim.fn.charidx(line, last_col - 1))
      end
    end
    vim.fn.setpos(".", { 0, row + 1, col + 1, 0 })
    vim.cmd.normal({ "o", bang = true })
    vim.fn.setpos(".", { 0, last_row + 1, last_col + 1, 0 })
  end)
end, "format: buffer or selection")

return M
