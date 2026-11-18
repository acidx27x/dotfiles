require("auto-session").setup({
  suppressed_dirs = { "~/", "/" },

  cwd_change_handling = false,

  git_use_branch_name = false,
  git_auto_restore_on_branch_change = false,

  args_allow_single_directory = true,
  args_allow_files_auto_save = false,

  auto_restore_last_session = false,
  bypass_save_filetypes = { "oil", "minifiles", "gitcommit", "gitrebase" },
  -- Close tool layouts through their APIs before the generic window cleanup.
  close_unsupported_windows = false,
  pre_save_cmds = {
    function()
      local diffview = package.loaded["diffview"]
      if diffview then
        for _, view in ipairs(vim.list_slice(require("diffview.lib").views)) do
          if not diffview.close(view.tabpage, { force = false }) then
            return false
          end
        end
      end

      if package.loaded["dapui"] then
        require("dapui").close()
      end
      if package.loaded["dap.repl"] then
        require("dap.repl").close()
      end
      require("auto-session.lib").close_unsupported_windows()
    end,
  },

  lazy_support = false,
  legacy_cmds = false,

  session_lens = {
    picker = "fzf",
    load_on_setup = false,
    picker_opts = {
      preview = { hidden = false },
    },
    mappings = {
      delete_session = { "i", "<M-bs>" },
    },
  },
})

local map = require("core.keymap")

map("n", "<leader>wr", "<cmd>AutoSession search<CR>", "session: search")
map("n", "<leader>ws", "<cmd>AutoSession save<CR>", "session: save")
map("n", "<leader>wa", "<cmd>AutoSession toggle<CR>", "session: toggle autosave")
