local pick = require("mini.pick")
local extra = require("mini.extra") -- extra pickers

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

local map = require("core.keymap")

map("n", "<leader>pr", ":Pick resume<CR>", "Pick: resume")
map("n", "<leader>pf", ":Pick files<CR>", "Pick: find files")
map("n", "<leader>pg", ":Pick grep_live<CR>", "Pick: find inside files with grep live")
map("n", "<leader>pb", ":Pick buffers<CR>", "Pick: find buffers")
map("n", "<leader>pd", ":Pick diagnostic<CR>", "Pick: find diagnostic")
map("n", "<leader>ps", ":Pick history<CR>", "Pick: find history")
map("n", "<leader>pp", ":Pick hipatterns<CR>", "Pick: find hipatterns")
map("n", "<leader>pk", ":Pick keymaps<CR>", "Pick: find keymaps")
map("n", '<leader>p"', ":Pick registers<CR>", "Pick: find registers")
map("n", "<leader>ph", ":Pick help<CR>", "Pick: find help")

map("n", "<leader>plc", ":Pick lsp scope='declaration'<CR>", "Pick: find lsp declaration")
map("n", "<leader>pld", ":Pick lsp scope='definition'<CR>", "Pick: find lsp definition")
map("n", "<leader>pls", ":Pick lsp scope='document_symbol'<CR>", "Pick: find lsp document symbol")
map("n", "<leader>pli", ":Pick lsp scope='implementation'<CR>", "Pick: find lsp implementation")
map("n", "<leader>plr", ":Pick lsp scope='references'<CR>", "Pick: find lsp references")
map("n", "<leader>plt", ":Pick lsp scope='type_definition'<CR>", "Pick: find lsp type definition")
map("n", "<leader>plS", ":Pick lsp scope='workspace_symbol'<CR>", "Pick: find lsp workspace symbol")
