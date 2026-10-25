local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  require("snipe").setup({
    ui = {
      position = "center", -- or topleft, topright

      open_win_override = {
        border = "rounded",
      },

      text_align = "right",
      persist_tags = true,
    },

    hints = {
      -- Charaters to use for hints (NOTE: make sure they don't collide with the navigation keymaps)
      dictionary = "sadflewcmpghio",
      -- Character used to disambiguate tags when 'persist_tags' option is set
      prefix_key = ".",
    },

    navigate = {
      leader = ",",
      -- Leader map defines keys that follow a selection prefixed by the
      -- leader key. For example (with tag "a"):
      -- ,ad -> run leader_map["d"](m, i)
      leader_map = {
        ["d"] = function(m, i)
          require("snipe").close_buf(m, i)
        end,
        ["v"] = function(m, i)
          require("snipe").open_vsplit(m, i)
        end,
        ["h"] = function(m, i)
          require("snipe").open_split(m, i)
        end,
      },

      next_page = "<C-f>",
      prev_page = "<C-b>",

      under_cursor = "<CR>",
      cancel_snipe = "<Esc>",
      close_buffer = "D",
      open_vsplit = "<C-s>",
      open_split = "<C-h>",
      -- change_tag   = "C",  -- or disable persist_tags
    },

    sort = "default", -- or last
  })
end

lazy.keymap("n", "<leader>sn", "snipe", "plugins.snipe-nvim-config", function()
  require("snipe").open_buffer_menu()
end, "buffer: open Snipe menu")

return M
