
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

keymap_ns("n", "<leader>pr",  ":Pick resume<CR>",     "Pick: resume")
keymap_ns("n", "<leader>pf",  ":Pick files<CR>",      "Pick: find files")
keymap_ns("n", "<leader>pg",  ":Pick grep_live<CR>",  "Pick: find inside files with grep live")
keymap_ns("n", "<leader>pb",  ":Pick buffers<CR>",    "Pick: find buffers")
keymap_ns("n", "<leader>pd",  ":Pick diagnostic<CR>", "Pick: find diagnostic")
keymap_ns("n", "<leader>ps",  ":Pick history<CR>",    "Pick: find history")
keymap_ns("n", "<leader>pp",  ":Pick hipatterns<CR>", "Pick: find hipatterns")
keymap_ns("n", "<leader>pk",  ":Pick keymaps<CR>",    "Pick: find keymaps")
keymap_ns("n", "<leader>p\"", ":Pick registers<CR>",  "Pick: find registers")
keymap_ns("n", "<leader>ph",  ":Pick help<CR>",       "Pick: find help")

keymap_ns("n", "<leader>plc", ":Pick lsp scope='declaration'<CR>",      "Pick: find lsp declaration")
keymap_ns("n", "<leader>pld", ":Pick lsp scope='definition'<CR>",       "Pick: find lsp definition")
keymap_ns("n", "<leader>pls", ":Pick lsp scope='document_symbol'<CR>",  "Pick: find lsp document symbol")
keymap_ns("n", "<leader>pli", ":Pick lsp scope='implementation'<CR>",   "Pick: find lsp implementation")
keymap_ns("n", "<leader>plr", ":Pick lsp scope='references'<CR>",       "Pick: find lsp references")
keymap_ns("n", "<leader>plt", ":Pick lsp scope='type_definition'<CR>",  "Pick: find lsp type definition")
keymap_ns("n", "<leader>plS", ":Pick lsp scope='workspace_symbol'<CR>", "Pick: find lsp workspace symbol")
