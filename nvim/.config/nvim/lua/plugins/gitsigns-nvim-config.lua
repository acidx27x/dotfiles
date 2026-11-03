require("gitsigns").setup({
  sign_priority = 100,
  attach_to_untracked = true,

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
        git.nav_hunk("next", { target = "all" })
      end
    end, "git: nav hunk next")

    keyn("[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        git.nav_hunk("prev", { target = "all" })
      end
    end, "git: nav hunk prev")

    -- Actions
    keyn("<leader>gs", git.stage_hunk, "git: stage/unstage hunk")
    keyn("<leader>gr", git.reset_hunk, "git: reset hunk")

    map("v", "<leader>gs", function()
      git.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "git: stage/unstage hunk (v)", { buf = bufnr })

    map("v", "<leader>gr", function()
      git.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "git: reset hunk (v)", { buf = bufnr })

    keyn("<leader>gS", git.stage_buffer, "git: stage buffer")
    keyn("<leader>gU", git.reset_buffer_index, "git: unstage buffer")
    keyn("<leader>gR", git.reset_buffer, "git: reset buffer")

    -- Previews
    keyn("<leader>gp", git.preview_hunk, "git: preview hunk")
    keyn("<leader>gP", git.preview_hunk_inline, "git: preview hunk inline")

    -- Blame
    keyn("<leader>gb", function()
      git.blame_line({ full = true })
    end, "git: blame line (full)")
    keyn("<leader>gB", git.blame, "git: blame")

    -- Diff
    keyn("<leader>gd", git.diffthis, "git: diff")
    keyn("<leader>gD", function()
      git.diffthis("~")
    end, "git: diff (~)")

    -- Changes tree
    keyn("<leader>gt", function()
      git.diff(nil, nil, { diff = "none" })
    end, "git: changes tree (no diff)")

    keyn("<leader>gT", function()
      git.diff(nil, nil, { diff = "unified" })
    end, "git: changes tree (unified)")

    -- Quickfix
    keyn("<leader>gq", git.setqflist, "git: qflist")
    keyn("<leader>gQ", function()
      git.setqflist("all")
    end, "git: qflist (all)")

    -- Location list
    keyn("<leader>gl", git.setloclist, "git: loclist")
    keyn("<leader>gL", function()
      git.setloclist(0, "all")
    end, "git: loclist (all)")

    -- Toggles
    keyn("<leader>gwd", git.toggle_word_diff, "git: toggle word diff")
    keyn("<leader>gib", git.toggle_current_line_blame, "git: toggle blame inline")

    -- Gitsigns attaches later, so refresh clues for its buffer-local maps.
    require("mini.clue").ensure_buf_triggers()
  end,
})
