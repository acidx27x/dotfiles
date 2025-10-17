
vim.g.disable_autoformat = true


require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua", lsp_format = "never", },

    c   = { "clang-format", lsp_format = "never", },
    cpp = { "clang-format", lsp_format = "never", },

    --["*"] = { "codespell" },
    --["_"] = { "trim_whitespace" },
    ["*"] = nil,
    ["_"] = nil,
  },

  default_format_opts = {
    timeout_ms = 1000,
    lsp_format = "never",
  },

  format_on_save    = function(bufnr) return end,
  format_after_save = function(bufnr) return end,

  log_level = vim.log.levels.WARN,
})


vim.keymap.set({'n', 'v'}, "<leader>cf", function()
  require("conform").format({ async = false, lsp_format = "never", })
end, { noremap = true, silent = true, desc = desc})
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

