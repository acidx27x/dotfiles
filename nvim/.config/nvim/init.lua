vim.loader.enable()

-- Install core mappings before plugins add theirs, and register package and buffer hooks
-- before Neovim reads the first file. LSP FileType hooks must be ready for that file too.
require("core.config")
require("plugins.spec").setup()
require("plugins.config")
require("lsp.config")
require("colorscheme.config")
-- MiniClue sees the complete startup keymap set and the colorscheme highlights.
require("plugins.mini-clue-config")
