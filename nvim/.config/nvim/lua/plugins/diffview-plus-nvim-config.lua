local diffview = require("diffview")
local actions = require("diffview.actions")
local map = require("core.keymap")

-- Keep buffer and diagnostic prefixes available in Diffview.
local panel_keymaps = {
  { "n", "<leader>b", false },
  { "n", "<leader>e", false },
  { "n", "<leader>ge", actions.focus_files, { desc = "Bring focus to the file panel" } },
  { "n", "<leader>gE", actions.toggle_files, { desc = "Toggle the file panel" } },
}

diffview.setup({
  keymaps = {
    view = panel_keymaps,
    file_panel = panel_keymaps,
    file_history_panel = panel_keymaps,
  },
  hooks = {
    view_closed = function()
      if vim.g.diffview_exit_on_close then
        vim.schedule(function()
          vim.cmd.qa()
        end)
      end
    end,
  },
})

map("n", "<leader>gt", function()
  diffview.toggle({})
end, "git: toggle repository diff")

map("n", "<leader>gT", function()
  diffview.open({ "--cached" })
end, "git: diff staged changes")
