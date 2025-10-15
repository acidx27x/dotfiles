
vim.g.barbar_auto_setup = false

require("barbar").setup({
  animation = false,

  exclude_ft   = {},
  exclude_name = {},

  icons = {
    buffer_index  = true,
    buffer_number = true,
    diagnostics = {
      [vim.diagnostic.severity.ERROR] = { enabled = true, icon = 'E', },
      [vim.diagnostic.severity.WARN]  = { enabled = true, icon = 'W', },
      [vim.diagnostic.severity.INFO]  = { enabled = false },
      [vim.diagnostic.severity.HINT]  = { enabled = false },
    },
    gitsigns = {
      added   = { enabled = true, icon = '✚', },
      changed = { enabled = true, icon = '', },
      deleted = { enabled = true, icon = '✖', },
    },
  },
  sort = {
    ignore_case = false,
  },
})

