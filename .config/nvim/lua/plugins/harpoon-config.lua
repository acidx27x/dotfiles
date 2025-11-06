
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  {
    src = "https://github.com/ThePrimeagen/harpoon",
    version = "harpoon2",
  },
})


local harpoon            = require("harpoon")
local harpoon_extensions = require("harpoon.extensions")

harpoon:setup()
harpoon:extend(harpoon_extensions.builtins.highlight_current_file())


local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
end

keymap_ns("n", "<leader>ha", function() harpoon:list():add() end, "harpoon: list add")
keymap_ns("n", "<leader>ht", function()
  harpoon.ui:toggle_quick_menu(harpoon:list(), { border = "rounded", ui_width_ratio = 0.60, })
end, "harpoon: toggle menu")

keymap_ns("n", "<leader>hn", function() harpoon:list():prev() end, "harpoon: list next")
keymap_ns("n", "<leader>hp", function() harpoon:list():next() end, "harpoon: list prev")

harpoon:extend({
  UI_CREATE = function(cx)
    vim.keymap.set("n", "<C-s>", function()
      harpoon.ui:select_menu_item({ vsplit = true, })
    end, { buffer = cx.bufnr, desc = "harpoon: open in split vertically", })

    vim.keymap.set("n", "<C-h>", function()
      harpoon.ui:select_menu_item({ split = true, })
    end, { buffer = cx.bufnr, desc = "harpoon: open in split horizontally", })

    vim.keymap.set("n", "<C-t>", function()
      harpoon.ui:select_menu_item({ tabedit = true, })
    end, { buffer = cx.bufnr, desc = "harpoon: open in tab", })
  end,
})

