
require("blink.cmp").setup({
  keymap = {
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation", },
    ["<C-h>"]     = {         "show_documentation", "hide_documentation", },
    ["<S-Tab>"]   = { "select_and_accept", "fallback", },
    ["<Tab>"]     = false,

    ["<C-e>"]     = { "hide",   "fallback" },
    ["<C-y>"]     = { "accept", "fallback" },
    ["<CR>"]      = false,

    ["<C-n>"] = { function(cmp) cmp.select_next({ auto_insert = false }) end, },  -- not working with default fb
    ["<C-p>"] = { function(cmp) cmp.select_prev({ auto_insert = false }) end, },  -- instantly fb to neovim c-n

    ["<C-b>"] = { "scroll_documentation_up",   "fallback", },
    ["<C-f>"] = { "scroll_documentation_down", "fallback", },

    ["<C-s>"] = { "show_signature", "hide_signature", },
    ["<C-u>"] = { "scroll_signature_up",   "fallback", },
    ["<C-d>"] = { "scroll_signature_down", "fallback", },
  },


  appearance = {
    nerd_font_variant = "nerd",
  },

  sources = {
    default            = { "lsp", "omni", "buffer", "path", "snippets", },
    min_keyword_length = 4,

    providers = {
      lsp = {
        enabled = true,
        name    = "lsp",
        module  = "blink.cmp.sources.lsp",
        score_offset = 10,
      },
      omni = {
        enabled = function() return vim.bo.omnifunc ~= "v:lua.vim.lsp.omnifunc" end,
        name    = "omni",
        module  = "blink.cmp.sources.complete_func",
        opts    = { complete_func = function() return vim.bo.omnifunc end, },
        score_offset = 9,
      },
      buffer = {
        enabled = true,
        name    = "buffer",
        module  = "blink.cmp.sources.buffer",
        score_offset = 8,
      },
      path = {
        enabled = true,
        name    = "path",
        module  = "blink.cmp.sources.path",
        score_offset = 7,
      },
      snippets = {
        enabled = false,
        name    = "snippets",
        module  = "blink.cmp.sources.snippets",
        score_offset = 1,
      },
    },
  },


  completion = {
    trigger = {
      show_in_snippet = false,
      show_on_backspace_after_accept       = false,
      show_on_backspace_after_insert_enter = false,
      show_on_trigger_character           = false,
      show_on_accept_on_trigger_character = false,
      show_on_insert_on_trigger_character = false,
    },

    accept = { auto_brackets = { enabled = false } },

    documentation = {
      auto_show = false,
    },

    list = {
      max_items = 100,
      selection = {
        preselect = true,
        auto_insert = true,
      },
      cycle = {
        from_top    = true,
        from_bottom = true,
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
      show_with_menu = false,
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
    completion = {
      list = {
        selection = {
          preselect   = false,
          auto_insert = true,
        },
      },
      menu = { auto_show = true, },
    },
  },


  term = { enabled = false, },


  signature = {
    enabled = true,
    trigger = {
      enabled = false,
    },
    window = { scrollbar = true, },
  },


  fuzzy = {
    sorts = {
      "score",
      "sort_text",
      "label",
    }
  },
})


local signature_trigger_show_old = require("blink.cmp.signature.trigger").show
require("blink.cmp.signature.trigger").show = function(opts)
  opts = opts or {}
  if require("blink.cmp").is_signature_visible() then
    opts.force = true
  end
  signature_trigger_show_old(opts)
end

