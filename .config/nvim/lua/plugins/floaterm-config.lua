
vim.pack.add({
  { src = "https://github.com/nvzone/volt" },
  { src = "https://github.com/nvzone/floaterm" },
})


local fterm       = require("floaterm")
local fterm_state = require("floaterm.state")

fterm.setup({
  border = true,

  mappings = {
    sidebar = function(bufnr)
      vim.keymap.set("n", "<Esc>", "<Nop>",
        { noremap = true, silent = true, buffer = bufnr, desc = "floaterm: disable escape key", })
      vim.keymap.set("n", "q", fterm.toggle,
        { noremap = true, silent = true, buffer = bufnr, desc = "floaterm: remap q to toggle", })
    end,
  },

  terminals = {
    { name = "Terminal" },
    -- cmd can be function too
    -- { name = "Terminal", cmd = "neofetch" },
  },
})


vim.keymap.set("n", "<leader>tf", fterm.toggle,
  { noremap = true, silent = true, desc = "floaterm: toggle float window", })

-- WARN: idk if this plugins is stable, this may brake if api changes
vim.api.nvim_create_user_command("FloatermClose", function()
  require("volt.utils").close({
    bufs = { fterm_state.buf, fterm_state.sidebuf, fterm_state.barbuf, },
    after_close = function()
      if fterm_state.bar_redraw_timer then require("floaterm.utils").close_timers() end
      fterm_state.volt_set = false
      fterm_state.terminals = nil
      fterm_state.buf     = nil
      fterm_state.sidebuf = nil
      fterm_state.barbuf  = nil
      vim.api.nvim_del_augroup_by_name("FloatermAu")
    end,
  })
end, { desc = "floaterm: close float window", })

