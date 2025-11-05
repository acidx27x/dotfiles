
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },
  { src = "https://github.com/onsails/lspkind.nvim" },
  -- { src = "https://github.com/Saghen/blink.cmp" },
  { src = "https://github.com/acidx27x/blink.cmp" },
})


require("lspkind").setup({
--
})


require("blink.cmp").setup({
  keymap = {
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation", },
    ["<C-h>"]     = {         "show_documentation", "hide_documentation", },
    ["<S-Tab>"]   = { "select_and_accept", "fallback", },
    ["<Tab>"]     = false,

    ["<C-e>"]     = { "hide",   "fallback", },
    ["<C-y>"]     = { "accept", "fallback", },
    ["<CR>"]      = false,

    ["<C-n>"] = { function(cmp) cmp.select_next({ auto_insert = false }) end, },  -- not working with default fb
    ["<C-p>"] = { function(cmp) cmp.select_prev({ auto_insert = false }) end, },  -- instantly fb to neovim c-n

    ["<C-b>"] = { "scroll_documentation_up",   "fallback", },
    ["<C-f>"] = { "scroll_documentation_down", "fallback", },

    ["<C-k>"] = false,
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
        name    = "LSP",
        module  = "blink.cmp.sources.lsp",
        score_offset = 10,
      },
      omni = {
        enabled = function() return vim.bo.omnifunc ~= "v:lua.vim.lsp.omnifunc" end,
        name    = "OMNI",
        module  = "blink.cmp.sources.complete_func",
        opts    = { complete_func = function() return vim.bo.omnifunc end, },
        score_offset = 9,
      },
      buffer = {
        enabled = true,
        name    = "BUF",
        module  = "blink.cmp.sources.buffer",
        score_offset = 8,
      },
      path = {
        enabled = true,
        name    = "PATH",
        module  = "blink.cmp.sources.path",
        score_offset = 7,
      },
      snippets = {
        enabled = false,
        name    = "SNIP",
        module  = "blink.cmp.sources.snippets",
        score_offset = 1,
      },
      cmdline = {
        name   = "CMD",
        module = 'blink.cmp.sources.cmdline',
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
        preselect   = true,
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
        columns = { { "label", "label_description", gap = 1 }, { "kind_icon" }, { "source_name" }, },
        components = {
          source_name = {
            width = { max = 30 },
            text = function(ctx)
              return "[" .. ctx.source_name .. "]"
            end,
            highlight = "BlinkCmpSource",
          },
          kind_icon = {  -- from doc/recipes.md
            text = function(ctx)
              if vim.tbl_contains({ "CMD" }, ctx.source_name) then
                return ctx.icon_gap
              end
              if vim.tbl_contains({ "PATH" }, ctx.source_name) then
                local mini_icon, _ = require("mini.icons").get_icon(ctx.item.data.type, ctx.label)
                if mini_icon then return mini_icon .. ctx.icon_gap end
              end
              local icon = require("lspkind").symbolic(ctx.kind, { mode = "symbol_text", })
              return icon .. ctx.icon_gap
            end,
            highlight = function(ctx)
              if vim.tbl_contains({ "PATH" }, ctx.source_name) then
                local mini_icon, mini_hl = require("mini.icons").get_icon(ctx.item.data.type, ctx.label)
                if mini_icon then return mini_hl end
              end
              return ctx.kind_hl
            end,
          },
          kind = {  -- from doc/recipes.md
            highlight = function(ctx)
              if vim.tbl_contains({ "Path" }, ctx.source_name) then
                local mini_icon, mini_hl = require("mini.icons").get_icon(ctx.item.data.type, ctx.label)
                if mini_icon then return mini_hl end
              end
              return ctx.kind_hl
            end,
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
    keymap = {
      preset = "cmdline",
      ["<C-n>"] = { function(cmp) cmp.select_next({ auto_insert = false }) end, },  -- not working with default fb
      ["<C-p>"] = { function(cmp) cmp.select_prev({ auto_insert = false }) end, },  -- instantly fb to neovim c-n
      ["<Left>"]  = false,
      ["<Right>"] = false,
    },
    sources = function()
      local type = vim.fn.getcmdtype()
      if type == '/' or type == '?' then return { "buffer", } end
      if type == ':' or type == '@' then return { "cmdline", "buffer", } end
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


  term = {
    enabled = true,
    keymap = {
      preset = "cmdline",
      ["<Tab>"]   = false,
      ["<S-Tab>"] = false,
      ["<Left>"]  = false,
      ["<Right>"] = false,
      ["<C-n>"] = { function(cmp) cmp.select_next({ auto_insert = false }) end, },  -- not working with default fb
      ["<C-p>"] = { function(cmp) cmp.select_prev({ auto_insert = false }) end, },  -- instantly fb to neovim c-n
    },
    sources = { "buffer", },
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


  signature = {
    enabled = true,
    trigger = {
      enabled = false,
    },
    window = { scrollbar = true, },
  },


  fuzzy = {
    frecency = {
      enabled = true,
      path    = vim.fn.stdpath("cache") .. '/blink/cmp/frecency.dat',
    },
    sorts = {
      "score",
      "sort_text",
      "label",
    },
    prebuilt_binaries = {
      force_version = "v1.7.0",  -- need to download binary
    },
  },
})


-- HACK
-- signature trigger is disabled by this configuration
-- so, when i trigger it manually, it is not sync with current argument position
-- that is why need to force to update it when it is shown manually
-- even with: signature = { trigger = { enabled = false, }, },
-- NOTE
-- this may be removed in future for new releases
-- when suitable api for dynamic trigger handling arrive
-- local signature_trigger_show_old = require("blink.cmp.signature.trigger").show
-- require("blink.cmp.signature.trigger").show = function(opts)
--   opts = opts or {}
--   if require("blink.cmp").is_signature_visible() then
--     opts.force = true
--   end
--   signature_trigger_show_old(opts)
-- end

