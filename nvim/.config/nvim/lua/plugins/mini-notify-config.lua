require("mini.notify").setup({
  lsp_progress = { enable = true },
  window = {
    config = function(buf)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local limit = math.max(1, math.min(80, math.floor(vim.o.columns * 0.382)))
      local width, height = 1, 0
      for _, line in ipairs(lines) do
        width = math.max(width, math.min(limit, vim.fn.strdisplaywidth(line)))
      end
      for _, line in ipairs(lines) do
        height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / width))
      end
      return { width = width, height = height }
    end,
  },
})

require("core.keymap")({ "n", "v" }, "<leader>nd", MiniNotify.clear, "notifications: dismiss")
