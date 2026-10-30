local function path_icon(ctx)
  local category = "file"
  if ctx.item.kind == vim.lsp.protocol.CompletionItemKind.Folder then
    category = "directory"
  end
  return require("mini.icons").get(category, ctx.label)
end

local blink = require("blink.cmp")
-- The native matcher may be missing from a fresh or mismatched Blink checkout.
if not blink.build then
  vim.notify(
    'Run :lua vim.pack.update({"blink.cmp"}, {target="lockfile"}) and restart for Blink v2',
    vim.log.levels.WARN
  )
  return
end
if not blink.library_available() and vim.fn.executable("cargo") == 1 then
  pcall(function()
    blink.build():pwait()
  end)
end
local use_rust = blink.library_available()

local function get_omnifunc()
  local func = vim.bo.omnifunc
  if func == "" or func == "v:lua.vim.lsp.omnifunc" then
    return nil
  end
  if func:match("^v:lua%.") or vim.fn.exists("*" .. func) == 1 then
    return func
  end
  local autoload = func:match("^(.*)#[^#]+$")
  if
    autoload
    and #vim.api.nvim_get_runtime_file("autoload/" .. autoload:gsub("#", "/") .. ".vim", false)
      > 0
  then
    return func
  end
end

blink.setup({
  keymap = {
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-h>"] = { "show_documentation", "hide_documentation" },
    ["<C-g>s"] = {
      function(cmp)
        return cmp.show({ providers = { "snippets" } })
      end,
    },
    ["<S-Tab>"] = { "snippet_backward", "select_and_accept", "fallback" },
    ["<Tab>"] = { "snippet_forward", "fallback" },

    ["<C-e>"] = { "hide", "fallback" },
    ["<C-y>"] = { "accept", "fallback" },
    ["<CR>"] = false,

    ["<C-n>"] = {
      function(cmp)
        return cmp.select_next({ auto_insert = false })
      end,
    },
    ["<C-p>"] = {
      function(cmp)
        return cmp.select_prev({ auto_insert = false })
      end,
    },

    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },

    ["<C-k>"] = false,
    ["<C-s>"] = { "show_signature", "hide_signature" },
    ["<C-u>"] = { "scroll_signature_up", "fallback" },
    ["<C-d>"] = { "scroll_signature_down", "fallback" },
  },

  appearance = {
    nerd_font_variant = "mono",
  },

  sources = {
    default = { "lsp", "omni", "buffer", "path", "snippets" },
    min_keyword_length = 4,

    providers = {
      lsp = {
        enabled = true,
        name = "LSP",
        module = "blink.cmp.sources.lsp",
        score_offset = 10,
        fallbacks = function(_, enabled_sources)
          return vim.tbl_contains(enabled_sources, "omni") and { "omni" } or { "buffer" }
        end,
      },
      omni = {
        enabled = function()
          return get_omnifunc() ~= nil
        end,
        name = "OMNI",
        module = "blink.cmp.sources.complete_func",
        opts = {
          complete_func = function()
            return get_omnifunc()
          end,
        },
        score_offset = 9,
        fallbacks = { "buffer" },
      },
      buffer = {
        enabled = true,
        name = "BUF",
        module = "blink.cmp.sources.buffer",
        score_offset = 8,
      },
      path = {
        enabled = true,
        name = "PATH",
        module = "blink.cmp.sources.path",
        score_offset = 7,
        fallbacks = {},
      },
      snippets = {
        enabled = true,
        name = "SNIP",
        module = "blink.cmp.sources.snippets",
        score_offset = 1,
      },
      cmdline = {
        name = "CMD",
        module = "blink.cmp.sources.cmdline",
        score_offset = 20, -- To have cmdline completions over buffer first in cmdline.
      },
    },
  },

  completion = {
    trigger = {
      show_in_snippet = false,
      show_on_backspace_after_accept = false,
      show_on_backspace_after_insert_enter = false,
      show_on_trigger_character = false,
    },

    accept = { auto_brackets = { enabled = false } },

    documentation = {
      auto_show = false,
    },

    list = {
      max_items = 100,
      selection = {
        preselect = true,
        auto_insert = false,
      },
      cycle = {
        from_top = true,
        from_bottom = true,
      },
    },

    menu = {
      auto_show = false,

      draw = {
        treesitter = { "lsp" },
        columns = { { "label", "label_description", gap = 1 }, { "kind_icon" }, { "source_name" } },
        components = {
          source_name = {
            width = { max = 30 },
            text = function(ctx)
              return "[" .. ctx.source_name .. "]"
            end,
            highlight = "BlinkCmpSource",
          },
          kind_icon = { -- From doc/recipes.md.
            text = function(ctx)
              if ctx.source_name == "CMD" then
                return ctx.icon_gap
              end
              if ctx.source_name == "PATH" then
                local mini_icon = path_icon(ctx)
                if mini_icon then
                  return mini_icon .. ctx.icon_gap
                end
              end
              local icon = require("mini.icons").get("lsp", ctx.kind)
              return icon .. ctx.icon_gap
            end,
            highlight = function(ctx)
              if ctx.source_name == "PATH" then
                local mini_icon, mini_hl = path_icon(ctx)
                if mini_icon then
                  return mini_hl
                end
              end
              return ctx.kind_hl
            end,
          },
        },
      },
    },

    ghost_text = {
      enabled = function()
        return vim.b.blink_ghost_typing == true
      end,
      show_with_menu = false,
    },
  },

  cmdline = {
    enabled = true,
    keymap = {
      preset = "cmdline",
      ["<C-n>"] = {
        function(cmp)
          return cmp.select_next({ auto_insert = true })
        end,
      },
      ["<C-p>"] = {
        function(cmp)
          return cmp.select_prev({ auto_insert = true })
        end,
      },
      ["<Left>"] = false,
      ["<Right>"] = false,
    },
    sources = {
      default = function()
        local type = vim.fn.getcmdtype()
        if type == "/" or type == "?" then
          return { "buffer" }
        end
        if type == ":" then
          return { "cmdline", "buffer" }
        end
        if type == "@" then
          return { "cmdline" }
        end
        return {}
      end,
    },
    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = true,
        },
      },
      menu = { auto_show = true },
    },
  },

  term = {
    enabled = true,
    keymap = {
      preset = "cmdline",
      ["<Tab>"] = false,
      ["<S-Tab>"] = false,
      ["<Left>"] = false,
      ["<Right>"] = false,
      ["<C-n>"] = {
        function(cmp)
          return cmp.select_next({ auto_insert = false })
        end,
      },
      ["<C-p>"] = {
        function(cmp)
          return cmp.select_prev({ auto_insert = false })
        end,
      },
    },
    sources = { default = { "buffer" } },
    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = true,
        },
      },
      menu = { auto_show = false },
    },
  },

  signature = {
    enabled = true,
    trigger = {
      enabled = false,
    },
    window = { scrollbar = true },
  },

  fuzzy = {
    implementation = use_rust and "rust" or "lua",
    frecency = {
      enabled = true,
      path = vim.fn.stdpath("cache") .. "/blink/cmp/frecency.dat",
    },
    sorts = {
      "score",
      "sort_text",
      "label",
    },
  },
})

-- Keep ghost text for edits, but clear it after cursor-only movement.
vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter", "TermEnter" }, {
  once = true,
  callback = function()
    if not use_rust then
      if
        require("core.tools").ensure_executable(nil, { "cargo" }, "Blink native matcher", true)
      then
        vim.notify_once("Blink native matcher unavailable; using Lua matcher", vim.log.levels.WARN)
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "InsertCharPre", "CursorMovedI" }, {
  callback = function(args)
    if args.event == "InsertCharPre" then
      vim.b[args.buf].blink_ghost_typing = true
      return
    end

    local tick = vim.api.nvim_buf_get_changedtick(args.buf)
    if args.event == "InsertEnter" then
      vim.b[args.buf].blink_ghost_typing = false
    elseif vim.b[args.buf].blink_ghost_tick == tick then
      vim.b[args.buf].blink_ghost_typing = false
      blink.hide()
    end
    vim.b[args.buf].blink_ghost_tick = tick
  end,
})
