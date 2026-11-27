local operators = require("mini.operators")

operators.setup({
  evaluate = { prefix = "<leader>xe" },
  exchange = { prefix = "<leader>xx" },
  multiply = { prefix = "<leader>xm" },
  replace = { prefix = "<leader>xr" },
  sort = {
    prefix = "<leader>xs",
    func = function(content)
      return operators.default_sort_func(content, {
        compare_fun = function(a, b)
          return a:lower() < b:lower()
        end,
      })
    end,
  },
})

vim.keymap.set("x", "<leader>xs", function()
  local mode = vim.fn.mode()
  local anchor, cursor = vim.fn.line("v"), vim.fn.line(".")
  operators.sort("visual")
  if vim.fn.mode() == mode then
    return
  end

  if mode == "V" then
    -- Sorting the entire buffer uses a temporary line that shifts the paste marks.
    vim.api.nvim_win_set_cursor(0, { anchor, 0 })
    vim.cmd.normal({ "V", bang = true })
    vim.api.nvim_win_set_cursor(0, { cursor, 0 })
  else
    vim.fn.setpos(".", vim.fn.getpos("'["))
    vim.cmd.normal({ mode, bang = true })
    vim.fn.setpos(".", vim.fn.getpos("']"))
    if vim.o.selection == "exclusive" then
      vim.cmd.normal({ "l", bang = true })
    end
  end
end, { silent = true, desc = "Sort selection" })
