
require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "c", "cpp",
    "bash", "fish",
    "lua",
    "javascript",
    "verilogams",
  },
  auto_install = false,
  highlight = {
    enable = true,
    disable = {
      --"c", "cpp",
    },
    additional_vim_regex_highlighting = false,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection    = "gnn", -- set to `false` to disable one of the mappings
      node_incremental  = "grn",
      scope_incremental = "grc",
      node_decremental  = "grm",
    },
  },
  indent = { enable = true },
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function()
    if require("nvim-treesitter.parsers").has_parser() then
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
    else
      vim.opt.foldmethod = "manual"
      vim.opt.foldexpr   = "0"
    end
  end,
})


-- Custom TS parsers
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

parser_config.verilogams = {
  install_info = {
    url = "~/Documents/proj/tree-sitter/tree-sitter-verilogams",
    files = { "src/parser.c" },

    branch = "main",
    generate_requires_npm = false,
    requires_generate_from_grammar = true,
  },
  filetype = { "va", "vams", },
}

