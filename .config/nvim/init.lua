
vim.loader.enable()

package.path = vim.fn.stdpath("config") .. "/lua/core/?.lua;"    .. package.path
package.path = vim.fn.stdpath("config") .. "/lua/plugins/?.lua;" .. package.path
package.path = vim.fn.stdpath("config") .. "/lua/lsp/?.lua;"     .. package.path

require("core.init")
require("plugins.init")
require("lsp.init")


package.path = vim.fn.stdpath("config") .. "/lua/colorscheme/?.lua;" .. package.path
require("colorscheme.init")

