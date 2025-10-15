require("mini.indentscope").setup({
  draw = {
    delay = 500,
    animation = require("mini.indentscope").gen_animation.none(),
    predicate = function(scope)
      return not scope.body.is_incomplete
    end,
  },

  mappings = {
    object_scope             = "",
    object_scope_with_border = "",
    goto_top    = "",
    goto_bottom = "",
  },

  symbol = '╎',
})


-- mb need to comment, depends on colorscheme
vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { force = true, link = "NonText", })

