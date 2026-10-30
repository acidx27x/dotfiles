local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  vim.g.disable_autoformat = true

  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },

      c = { "clang-format" },
      cpp = { "clang-format" },

      cmake = {
        "gersemi",
        filter = function(client)
          return client.name ~= "neocmake"
        end,
      },

      python = {
        "ruff_format",
        filter = function(client)
          return client.name ~= "ruff"
        end,
      },

      --["*"] = { "codespell" },
      --["_"] = { "trim_whitespace" },
      ["*"] = nil,
      ["_"] = nil,
    },

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
      return
    end,
    format_after_save = function(bufnr)
      return
    end,

    log_level = vim.log.levels.WARN,
  })

  -- conform.format({ formatters = { "ruff_fix" } }) to use with specific formater for injected code

  -- example
  --require("conform").setup({
  --  formatters = {
  --    yamlfix = {
  --      -- Change where to find the command
  --      command = "local/path/yamlfix",
  --      command = require("conform.util").find_executable({"local/path/to/dir",}, "yamlfix")
  --      -- Adds environment args to the yamlfix formatter
  --      env = {
  --        YAMLFIX_SEQUENCE_STYLE = "block_style",
  --      },
  --    },
  --    args = { "-filename", "$FILENAME", "-i", "2" },
  --    append_args = { "-i", "2" },
  --  },
  --})
end

lazy.keymap({ "n", "v" }, "<leader>cf", "conform", "plugins.conform-nvim-config", function()
  local conform = require("conform")
  local commands = {
    stylua = "stylua",
    ["clang-format"] = "clang-format",
    gersemi = "gersemi",
    ruff_format = "ruff",
  }
  local available, has_lsp = conform.list_formatters_to_run(0)
  local can_continue = has_lsp or #available > 0
  for _, name in ipairs(conform.list_formatters_for_buffer(0)) do
    local key = name == "ruff_format" and "ruff" or name
    local command =
      require("core.tools").ensure_executable(key, { commands[name] }, "Formatting", can_continue)
    if command then
      conform.formatters[name] = vim.tbl_extend("force", conform.formatters[name] or {}, {
        command = command,
      })
    elseif not can_continue then
      return
    end
  end
  conform.format({ async = false })
end, "format: buffer or selection")

return M
