vim.loader.enable()

require("core.config")
require("plugins.spec").setup()
require("plugins.config")
require("lsp.config")
require("colorscheme.config")

-- Register plugin and filetype autocommands before loading command-line buffers.
vim.cmd.syntax("on")
