
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },  -- uses by default, fb to nvim-web-devicons
  { src = "https://github.com/nvim-mini/mini.extra" },
  -- { src = "https://github.com/nvim-mini/mini.pick" },
  { src = "https://github.com/acidx27x/mini.pick" },  -- fork to be able to edit glob patterns
})


local pick  = require("mini.pick")
local extra = require("mini.extra")  -- extra pickers


-- also redefines vim.ui.select
pick.setup({
--
})
extra.setup()

-- add cwd argument to Pick
pick.registry.files = function(local_opts)
  local opts = { source = { cwd = local_opts.cwd } }
  local_opts.cwd = nil
  return pick.builtin.files(local_opts, opts)
end

pick.registry.grep = function(local_opts)
  local opts = { source = { cwd = local_opts.cwd } }
  local_opts.cwd = nil
  return pick.builtin.grep(local_opts, opts)
end

pick.registry.grep_live = function(local_opts)
  local opts = { source = { cwd = local_opts.cwd } }
  local_opts.cwd = nil
  return pick.builtin.grep_live(local_opts, opts)
end


local function keymap_ns(mode, key, func, desc)
  vim.keymap.set(mode, key, func, { noremap = true, silent = true, desc = desc, })
end

keymap_ns("n", "<leader>pb", ":Pick buffers<CR>", "Pick: find buffers")
keymap_ns("n", "<leader>pf", ":Pick files<CR>", "Pick: find files")
keymap_ns("n", "<leader>pg", ":Pick grep_live<CR>", "Pick: find inside files with grep live")
keymap_ns("n", "<leader>pk", ":Pick keymaps<CR>", "Pick: find keymaps")
keymap_ns("n", "<leader>ph", ":Pick help<CR>", "Pick: find help")
keymap_ns("n", "<leader>pr", ":Pick resume<CR>", "Pick: resume")

