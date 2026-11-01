require("mini.operators").setup({
  evaluate = { prefix = "<leader>xe" },
  exchange = { prefix = "<leader>xx" },
  multiply = { prefix = "<leader>xm" },
  replace = { prefix = "<leader>xr" },
  sort = {
    prefix = "<leader>xs",
    func = function(content)
      return MiniOperators.default_sort_func(content, {
        compare_fun = function(a, b)
          return a:lower() < b:lower()
        end,
      })
    end,
  },
})
