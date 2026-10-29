local M = {}

function M.setup(command)
  require("actions-preview").setup({
    diff = {
      algorithm = "patience",
      ignore_whitespace = true,
    },

    highlight_command = command and {
      require("actions-preview.highlight").diff_so_fancy(command),
    } or {},

    backend = { "minipick" },
  })
end

return M
