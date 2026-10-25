require("gitsigns").setup({
  sign_priority = 100,

  on_attach = function(bufnr)
    local git = require("gitsigns")
    local map = require("core.keymap")

    local function keyn(key, func, desc)
      map("n", key, func, desc, { buf = bufnr })
    end

    -- Navigation
    keyn("]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        git.nav_hunk("next")
      end
    end, "git: nav hunk next")

    keyn("[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        git.nav_hunk("prev")
      end
    end, "git: nav hunk prev")

    -- Actions
    keyn("<leader>gs", git.stage_hunk, "git: stage hunk (n)")
    keyn("<leader>gr", git.reset_hunk, "git: reset hunk (n)")

    map("v", "<leader>gs", function()
      git.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "git: stage hunk (v)", { buf = bufnr })

    map("v", "<leader>gr", function()
      git.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "git: reset hunk (v)", { buf = bufnr })

    keyn("<leader>gS", git.stage_buffer, "git: stage buffer")
    keyn("<leader>gR", git.reset_buffer, "git: reset buffer")
    keyn("<leader>gp", git.preview_hunk, "git: preview hunk")
    keyn("<leader>gi", git.preview_hunk_inline, "git: preview hunk inline")

    keyn("<leader>gb", function()
      git.blame_line({ full = true })
    end, "git: blame line (full)")
    keyn("<leader>gB", git.blame, "git: blame")

    keyn("<leader>gd", git.diffthis, "git: diff")
    keyn("<leader>gD", function()
      git.diffthis("~")
    end, "git: diff (~)")

    keyn("<leader>gq", git.setqflist, "git: qflist")
    keyn("<leader>gQ", function()
      git.setqflist("all")
    end, "git: qflist (all)")

    -- Toggles
    keyn("<leader>gtw", git.toggle_word_diff, "git: toggle word diff")
    keyn("<leader>gtb", git.toggle_current_line_blame, "git: toggle blame inline")

    require("mini.clue").ensure_buf_triggers()
  end,
})
