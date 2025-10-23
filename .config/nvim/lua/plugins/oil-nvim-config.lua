
require("oil").setup({  --TODO winbar toggle additional info size etc how to open oild split directory
  delete_to_trash = false,

  lsp_file_methods = { enabled = false, },

  use_default_keymaps = false,
  keymaps = {
    ["<leader>o?"] = { "actions.show_help", mode = "n", desc = "Oil: show help", },

    ["<CR>"]       = { "actions.select", mode = "n", desc = "Oil: select", },
    ["<leader>ov"] = { "actions.select", mode = "n", opts = { vertical = true }, desc = "Oil: select in vertical", },
    ["<leader>oh"] = { "actions.select", mode = "n", opts = { horizontal = true }, desc = "Oil: select in horizontal", },
    ["<leader>ot"] = { "actions.select", mode = "n", opts = { tab = true }, desc = "Oil: select in tab", },

    ["<leader>op"] = { "actions.preview", mode = "n", desc = "Oil: toggle preview", },
    ["<leader>oc"] = { "actions.close", mode = "n", desc = "Oil: close", },
    ["<leader>or"] = { "actions.refresh", mode = "n", desc = "Oil: refresh", },

    ["<leader>ob"] = { "actions.open_cwd", mode = "n", desc = "Oil: open cwd", },
    ["<leader>o."] = { "actions.cd", mode = "n", desc = "Oil: cd", },
    ["<leader>o,"] = { "actions.cd", opts = { scope = "tab" }, mode = "n", desc = "Oil: cd (tab)", },

    ["<leader>os"] = { "actions.change_sort", mode = "n", desc = "Oil: change sort", },
    ["<leader>ox"] = { "actions.open_external", mode = "n", desc = "Oil: open external", },
    ["<leader>oi"] = { "actions.toggle_hidden", mode = "n", desc = "Oil: toggle hidden", },
    ["<leader>o/"] = { "actions.toggle_trash", mode = "n", desc = "Oil: toggle trash", },
  },

  view_options = {
    show_hidden = true,
    highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
      return nil  -- TODO
    end,
  },
})

