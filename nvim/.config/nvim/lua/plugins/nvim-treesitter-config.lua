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

local selections = {}

local function select_node(node)
  if not node then
    return
  end

  local start_row, start_col, end_row, end_col = node:range()
  if end_col == 0 and end_row > start_row then
    end_row = end_row - 1
    end_col = #vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1]
  else
    end_col = math.max(end_col - 1, start_col)
  end

  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd.normal({ "v", bang = true })
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

local function start_selection()
  local bufnr = vim.api.nvim_get_current_buf()
  local node = vim.treesitter.get_node({ bufnr = bufnr })
  selections[bufnr] = node and { node } or nil
  select_node(node)
end

local function grow_selection()
  local bufnr = vim.api.nvim_get_current_buf()
  local stack = selections[bufnr]
  if not stack or #stack == 0 then
    start_selection()
    return
  end

  local parent = stack[#stack]:parent()
  if parent then
    table.insert(stack, parent)
    select_node(parent)
  end
end

local function shrink_selection()
  local stack = selections[vim.api.nvim_get_current_buf()]
  if not stack or #stack <= 1 then
    return
  end

  table.remove(stack)
  select_node(stack[#stack])
end

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

    local opts = { buf = args.buf, silent = true }
    map("n", "gnn", start_selection, "Tree-sitter: start node selection", opts)
    map("x", "grn", grow_selection, "Tree-sitter: grow node selection", opts)
    map("x", "grc", grow_selection, "Tree-sitter: grow scope selection", opts)
    map("x", "grm", shrink_selection, "Tree-sitter: shrink node selection", opts)

    -- These buffer-local selection maps arrive after MiniClue's initial trigger scan.
    require("mini.clue").ensure_buf_triggers()
  end,
  desc = "Enable Tree-sitter features for configured filetypes",
})
