
require("gitsigns").setup({
  on_attach = function(bufnr)
    local git = require("gitsigns")

    local function getopts(desc)
      return { noremap = true, silent = true, buffer = bufnr, desc = desc }
    end
    local function keyn(key, func, opts)
      vim.keymap.set("n", key, func, opts)
    end

    -- Navigation
    keyn("]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true, })
      else
        git.nav_hunk("next")
      end
    end, getopts("git: nav hunk next"))

    keyn("[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true, })
      else
        git.nav_hunk("prev")
      end
    end, getopts("git: nav hunk prev"))

    -- Actions
    keyn("<leader>gs", git.stage_hunk, getopts("git: stage hunk (n)"))
    keyn("<leader>gr", git.reset_hunk, getopts("git: reset hunk (n)"))

    vim.keymap.set("v", "<leader>gs", function()
      git.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, getopts("git: stage hunk (v)"))

    vim.keymap.set("v", "<leader>gr", function()
      git.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, getopts("git: reset hunk (v)"))

    keyn("<leader>gS", git.stage_buffer, getopts("git: stage buffer"))
    keyn("<leader>gR", git.reset_buffer, getopts("git: reset buffer"))
    keyn("<leader>gp", git.preview_hunk, getopts("git: preview hunk"))
    keyn("<leader>gi", git.preview_hunk_inline, getopts("git: preview hunk inline"))

    keyn("<leader>gb", function() git.blame_line({ full = true }) end, getopts("git: blame line (full)"))
    keyn("<leader>gB", git.blame, getopts("git: blame"))

    keyn("<leader>gd", git.diffthis, getopts("git: diff"))
    keyn("<leader>gD", function() git.diffthis("~") end, getopts("git: diff (~)"))

    keyn("<leader>gq", git.setqflist, getopts("git: qflist"))
    keyn("<leader>gQ", function() git.setqflist("all") end, getopts("git: qflist (all)"))

    -- Toggles
    keyn("<leader>gtw", git.toggle_word_diff, getopts("git: toggle word diff"))
    keyn("<leader>gtb", git.toggle_current_line_blame, getopts("git: toggle blame inline"))
  end
})

