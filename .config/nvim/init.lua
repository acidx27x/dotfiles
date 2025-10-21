
vim.loader.enable()

package.path = vim.fn.stdpath("config") .. "/lua/core/?.lua;"    .. package.path
package.path = vim.fn.stdpath("config") .. "/lua/plugins/?.lua;" .. package.path
require("core.config")
require("plugins.config")

package.path = vim.fn.stdpath("config") .. "/lua/lsp/?.lua;" .. package.path
package.path = vim.fn.stdpath("config") .. "/lua/dap/?.lua;" .. package.path
require("lsp.config")
require("dap.config")


package.path = vim.fn.stdpath("config") .. "/lua/colorscheme/?.lua;" .. package.path
require("colorscheme.config")

