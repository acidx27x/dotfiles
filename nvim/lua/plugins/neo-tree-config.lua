
require("neo-tree").setup({
  popup_border_style = "",

  source_selector = {
    winbar     = false,
    statusline = true,
  },

  filesystem = {
    bind_to_cwd = false,
  },

  buffers = {
    bind_to_cwd = false,
  },

  default_component_configs = {
    container = {
      right_padding = 1,
    },
  },
})


-- mb need to comment, depends on colorscheme
vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = "none", bg = "none" })


local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc})
end

keymap_ns("n", "<leader>|o", ":Neotree action=focus<CR>", "Neo-tree open")
keymap_ns("n", "<leader>|c", ":Neotree action=close<CR>", "Neo-tree close")
keymap_ns("n", "<leader>|t", ":Neotree toggle<CR>", "Neo-tree toggle")

keymap_ns("n", "<leader>|rn", function()
  local path = vim.fn.expand("%:p") -- full path of current file
  vim.cmd("Neotree position=left reveal_file=" .. vim.fn.fnameescape(path))
end, "Neo-tree reveal file from cwd")
keymap_ns("n", "<leader>|rf", function()
  local path = vim.fn.expand("%:p") -- full path of current file
  vim.cmd("Neotree position=float reveal_file=" .. vim.fn.fnameescape(path) .. " reveal_force_cwd")
end, "Neo-tree reveal file from anywhere")

