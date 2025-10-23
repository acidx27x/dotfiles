
require("oil").setup({  --TODO winbar toggle additional info size etc how to open oild split directory
  delete_to_trash = true,

  lsp_file_methods = { enabled = false, },

  buf_options = {
    buflisted = true,
    bufhidden = "",
  },

  use_default_keymaps = false,
  keymaps = {
    ["<leader>o?"] = { "actions.show_help", mode = "n", desc = "Oil: show help", },
    ["<CR>"] = { "actions.select", desc = "Oil: select", },
    ["<C-s>"] = { "actions.select", opts = { vertical = true } },
    ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-t>"] = { "actions.select", opts = { tab = true } },
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = { "actions.close", mode = "n" },
    ["<C-l>"] = "actions.refresh",
    ["-"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },

  view_options = {
    show_hidden = true,
    highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
      return nil  -- TODO
    end,
  },
})

