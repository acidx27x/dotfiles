
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.hipatterns" },
})


local hipatterns = require("mini.hipatterns")


hipatterns.setup({
  highlighters = {  -- %w_ ignore words like FATAL_ERROR
    fixme = { pattern = "%f[%w_]()FIXME()%f[^%w_]", group = "MiniHipatternsFixme", },
    error = { pattern = "%f[%w_]()ERROR()%f[^%w_]", group = "MiniHipatternsFixme", },

    hack  = { pattern = "%f[%w_]()HACK()%f[^%w_]",  group = "MiniHipatternsHack",  },
    warn  = { pattern = "%f[%w_]()WARN()%f[^%w_]",  group = "MiniHipatternsHack",  },

    todo  = { pattern = "%f[%w_]()TODO()%f[^%w_]",  group = "MiniHipatternsTodo",  },

    note  = { pattern = "%f[%w_]()NOTE()%f[^%w_]",  group = "MiniHipatternsNote",  },
    hint  = { pattern = "%f[%w_]()HINT()%f[^%w_]",  group = "MiniHipatternsNote",  },
    info  = { pattern = "%f[%w_]()INFO()%f[^%w_]",  group = "MiniHipatternsNote",  },

    -- Highlight hex color strings (`#rrggbb`) using that color
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },

  delay = {
    scroll      = 200,
    text_change = 200,
  },
})

