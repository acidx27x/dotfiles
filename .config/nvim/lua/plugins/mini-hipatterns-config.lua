
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.hipatterns" },
})


local hipatterns = require("mini.hipatterns")


hipatterns.setup({
  highlighters = {
    -- Highlight standalone "FIXME", "HACK", "TODO", "NOTE"
    fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme", },
    error = { pattern = "%f[%w]()ERROR()%f[%W]", group = "MiniHipatternsFixme", },

    hack  = { pattern = "%f[%w]()HACK()%f[%W]",  group = "MiniHipatternsHack",  },
    warn  = { pattern = "%f[%w]()WARN()%f[%W]",  group = "MiniHipatternsHack",  },

    todo  = { pattern = "%f[%w]()TODO()%f[%W]",  group = "MiniHipatternsTodo",  },

    note  = { pattern = "%f[%w]()NOTE()%f[%W]",  group = "MiniHipatternsNote",  },
    hint  = { pattern = "%f[%w]()HINT()%f[%W]",  group = "MiniHipatternsNote",  },
    info  = { pattern = "%f[%w]()INFO()%f[%W]",  group = "MiniHipatternsNote",  },

    -- Highlight hex color strings (`#rrggbb`) using that color
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },

  delay = {
    scroll      = 200,
    text_change = 200,
  },
})

