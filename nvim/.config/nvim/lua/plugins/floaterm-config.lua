local lazy = require("plugins.lazy")
local M = {}

function M.setup()
  local fterm = require("floaterm")
  local fterm_state = require("floaterm.state")
  local map = require("core.keymap")

  fterm.setup({
    border = true,

    mappings = {
      sidebar = function(bufnr)
        map("n", "<Esc>", "<Nop>", "floaterm: disable escape key", { buf = bufnr })
        map("n", "q", fterm.toggle, "floaterm: remap q to toggle", { buf = bufnr })
      end,
    },

    terminals = {
      { name = "Terminal" },
      -- cmd can be function too
      -- { name = "Terminal", cmd = "neofetch" },
    },
  })

  -- WARN: idk if this plugins is stable, this may brake if api changes
  vim.api.nvim_create_user_command("FloatermClose", function()
    require("volt.utils").close({
      bufs = { fterm_state.buf, fterm_state.sidebuf, fterm_state.barbuf },
      after_close = function()
        if fterm_state.bar_redraw_timer then
          require("floaterm.utils").close_timers()
        end
        fterm_state.volt_set = false
        fterm_state.terminals = nil
        fterm_state.buf = nil
        fterm_state.sidebuf = nil
        fterm_state.barbuf = nil
        vim.api.nvim_del_augroup_by_name("FloatermAu")
      end,
    })
  end, { desc = "floaterm: close float window" })
end

lazy.keymap("n", "<leader>tf", "floaterm", "plugins.floaterm-config", function()
  require("floaterm").toggle()
end, "terminal: toggle floating terminal")

return M
