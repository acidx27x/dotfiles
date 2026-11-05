local treesitter = require("nvim-treesitter")
local map = require("core.keymap")

local parsers = {
  "diff",
  "bash",
  "fish",
  "c",
  "cpp",
  "cmake",
  "python",
  "lua",
  "javascript",
}

local filetypes = {
  "diff",
  "sh",
  "fish",
  "c",
  "cpp",
  "cmake",
  "python",
  "lua",
  "javascript",
}

treesitter.setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

local function parser_tools()
  local tools = require("core.tools")
  local cli_ok = tools.ensure_executable(nil, { "tree-sitter" }, "Parser installation")
  local tar_ok = tools.ensure_executable(nil, { "tar" }, "Parser installation")
  local download_ok = tools.ensure_executable(nil, { "curl" }, "Parser installation")
  local compiler_ok = tools.ensure_executable(nil, { "cc", "clang", "gcc" }, "Parser installation")
  return cli_ok and tar_ok and download_ok and compiler_ok
end

local function complete_parsers(installed)
  return function(arglead)
    local available =
      require("nvim-treesitter.config")[installed and "get_installed" or "get_available"]()
    return vim.tbl_filter(function(name)
      return name:find(arglead, 1, true) ~= nil
    end, available)
  end
end

vim.api.nvim_create_user_command("TSInstallConfigured", function()
  if parser_tools() then
    treesitter.install(parsers)
  end
end, { desc = "Install the configured Tree-sitter parsers" })

vim.api.nvim_create_user_command("TSInstall", function(args)
  if parser_tools() then
    require("nvim-treesitter.install").install(args.fargs, { force = args.bang, summary = true })
  end
end, { nargs = "+", bang = true, bar = true, complete = complete_parsers(false) })

vim.api.nvim_create_user_command("TSInstallFromGrammar", function(args)
  if parser_tools() then
    require("nvim-treesitter.install").install(args.fargs, {
      generate = true,
      summary = true,
      force = args.bang,
    })
  end
end, { nargs = "+", bang = true, bar = true, complete = complete_parsers(false) })

vim.api.nvim_create_user_command("TSUpdate", function(args)
  if parser_tools() then
    require("nvim-treesitter.install").update(args.fargs, { summary = true })
  end
end, { nargs = "*", bar = true, complete = complete_parsers(true) })

-- Mirror native an/in's parser check so the aliases retain LSP fallback too.
local function select_node(target)
  if vim.treesitter.get_parser(0, nil, { error = false }) then
    vim.treesitter.select(target, vim.v.count1)
  else
    vim.lsp.buf.selection_range(target == "parent" and vim.v.count1 or -vim.v.count1)
  end
end

local function grow_selection()
  select_node("parent")
end

map("n", "gnn", grow_selection, "selection: start node selection")
map("x", "grn", grow_selection, "selection: grow to parent")
map("x", "grc", grow_selection, "selection: grow to parent (alias)")
map("x", "grm", function()
  select_node("child")
end, "selection: shrink to child")

local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = filetypes,
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then
      return
    end

    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  end,
  desc = "Enable Tree-sitter features for configured filetypes",
})
