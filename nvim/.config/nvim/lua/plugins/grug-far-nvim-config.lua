local function open(visual)
  local rg = require("core.tools").ensure_executable("rg", { "rg" }, "grug-far")
  if not rg then
    return
  end

  require("plugins.spec").load("grug_far")
  local grug = require("grug-far")
  local cwd = vim.fn.getcwd()
  local opts = {
    engine = "ripgrep",
    engines = { ripgrep = { path = rg, extraArgs = "--ignore-case" } },
    -- A separate instance per directory keeps toggled searches rooted at their invocation.
    instanceName = "search:" .. cwd,
    visualSelectionUsage = "prefill-search",
  }
  if visual then
    opts.instanceName = nil
    grug.with_visual_selection(opts)
  else
    if vim.bo.filetype == "grug-far" then
      local _, name = grug.get_instance(vim.api.nvim_get_current_buf())
      opts.instanceName = name
    end
    grug.toggle_instance(opts)
  end
  -- grug-far runs its engine in the search window's cwd.
  if vim.bo.filetype == "grug-far" then
    vim.cmd.lcd(vim.fn.fnameescape(cwd))
  end
end

local map = require("core.keymap")
map("n", "<leader>S", function()
  open(false)
end, "search: toggle grug-far")
map("x", "<leader>S", function()
  open(true)
end, "search: prefill selection in grug-far")
