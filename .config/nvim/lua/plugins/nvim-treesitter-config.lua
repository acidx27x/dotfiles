
vim.pack.add({
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    version = "master",
    -- version = "main",  -- future update config is not compatible
  },
})


require("nvim-treesitter.configs").setup({
  auto_install = false,
  ensure_installed = {
    "diff",
    "bash", "fish",

    "c", "cpp",
    "python",
    "lua",
    "javascript",

    -- "verilogams",
  },

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

  indent = { enable = true, },
})


vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function()
    if require("nvim-treesitter.parsers").has_parser() then
      vim.wo.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
    else
      vim.wo.foldexpr   = "0"
    end
  end,
})


-- Custom TS parsers
-- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
--
-- parser_config.verilogams = {
--   install_info = {
--     url = "~/Documents/proj/tree-sitter/tree-sitter-verilogams",
--     files = { "src/parser.c" },
--
--     branch = "main",
--     generate_requires_npm = false,
--     requires_generate_from_grammar = true,
--   },
--   filetype = { "va", "vams", },
-- }
--
