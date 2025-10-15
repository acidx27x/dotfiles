
require("blink.cmp").setup({
  keymap = {
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation", },
    ["<C-h>"]     = { "show_documentation", "hide_documentation", },
    ["<S-Tab>"]   = { "select_and_accept", "fallback", },
    ["<Tab>"]     = false,

    ["<C-e>"]     = { "hide",   "fallback" },
    ["<C-y>"]     = { "accept", "fallback" },
    ["<CR>"]      = false,

    ["<C-n>"] = { function(cmp) cmp.select_next({ auto_insert = false }) end, },  -- not working with default fb
    ["<C-p>"] = { function(cmp) cmp.select_prev({ auto_insert = false }) end, },  -- instantly fb to neovim c-n

    ["<C-b>"] = { "scroll_documentation_up",   "fallback", },
    ["<C-f>"] = { "scroll_documentation_down", "fallback", },

    ["<C-k>"] = { "show_signature",        "hide_signature", },
    ["<C-u>"] = { "scroll_signature_up",   "fallback", },
    ["<C-d>"] = { "scroll_signature_down", "fallback", },
  },


  appearance = {
    nerd_font_variant = "nerd",
  },


  sources = {
    default            = { "lsp", "buffer", "path", "snippets", },
    min_keyword_length = 4,

    providers = {
      lsp = {
        enabled = true,
        name    = "lsp",
        module  = "blink.cmp.sources.lsp",
        score_offset = 10,
      },
      buffer = {
        enabled = true,
        name    = "buffer",
        module  = "blink.cmp.sources.buffer",
        score_offset = 9,
      },
      path = {
        enabled = true,
        name    = "path",
        module  = "blink.cmp.sources.path",
        score_offset = 8,
      },
      snippets = {
        enabled = true,
        name    = "snippets",
        module  = "blink.cmp.sources.snippets",
        score_offset = 0,
      },
      omni = { enabled = false, },
    },
  },


  completion = {
    accept = { auto_brackets = { enabled = false } },

    documentation = {
      auto_show = false,
    },

    list = {
      max_items = 50,
      selection = {
        auto_insert = true,
        preselect = true,
      },
      cycle = {
        from_bottom = true,
        from_top    = true,
      },
    },

    menu = {
      auto_show = false,

      draw = {
        treesitter = { "lsp" },
        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
        components = {
          source_name = {
            width = { max = 30 },
            text = function(ctx)
              return "[" .. ctx.source_name .. "]"
            end,
            highlight = "BlinkCmpSource",
          },
        },
      },
    },

    ghost_text = {
      enabled        = true,
      show_with_menu = true,
    },
  },


  cmdline = {
    enabled = true,
    keymap = { preset = "cmdline" },
    sources = function()
      local type = vim.fn.getcmdtype()
      if type == '/' or type == '?' then return { "buffer" } end
      if type == ':' or type == '@' then return { "cmdline", "buffer" } end
      return {}
    end,
    completion = { menu = { auto_show = false, }, },
  },


  term = { enabled = false, },


  signature = {
    enabled = true,
    trigger = { enabled = false, },
    window = { scrollbar = true, },
  },


  fuzzy = {
    sorts = {
      "exact",
      "score",
      "sort_text",
    }
  },
})

