local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  local harpoon = require("harpoon")
  local harpoon_extensions = require("harpoon.extensions")

  harpoon:setup()
  harpoon:extend(harpoon_extensions.builtins.highlight_current_file())

  local map = require("core.keymap")

  harpoon:extend({
    UI_CREATE = function(cx)
      map("n", "<C-s>", function()
        harpoon.ui:select_menu_item({ vsplit = true })
      end, "harpoon: open in split vertically", { buf = cx.bufnr })

      map("n", "<C-h>", function()
        harpoon.ui:select_menu_item({ split = true })
      end, "harpoon: open in split horizontally", { buf = cx.bufnr })

      map("n", "<C-t>", function()
        harpoon.ui:select_menu_item({ tabedit = true })
      end, "harpoon: open in tab", { buf = cx.bufnr })
    end,
  })
end

lazy.keymap("n", "<leader>ha", "harpoon", "plugins.harpoon-config", function()
  require("harpoon"):list():add()
end, "harpoon: add current file")
lazy.keymap("n", "<leader>ht", "harpoon", "plugins.harpoon-config", function()
  local harpoon = require("harpoon")
  harpoon.ui:toggle_quick_menu(harpoon:list(), { border = "rounded", ui_width_ratio = 0.60 })
end, "harpoon: toggle menu")
lazy.keymap("n", "<leader>hn", "harpoon", "plugins.harpoon-config", function()
  require("harpoon"):list():next()
end, "harpoon: next item")
lazy.keymap("n", "<leader>hp", "harpoon", "plugins.harpoon-config", function()
  require("harpoon"):list():prev()
end, "harpoon: previous item")

return M
