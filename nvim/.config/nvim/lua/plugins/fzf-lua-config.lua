local fzf = require("fzf-lua")

fzf.setup({
  ui_select = {},
  file_icons = "mini",
  winopts = {
    height = 0.8,
    width = 0.8,
    row = 0.5,
    col = 0.5,
    border = "rounded",
    preview = { layout = "flex", border = "rounded" },
  },
  hls = {
    normal = "NormalFloat",
    border = "FloatBorder",
    preview_normal = "NormalFloat",
    preview_border = "FloatBorder",
  },
  keymap = {
    builtin = {
      true,
      ["<M-/>"] = "toggle-help",
      ["<M-z>"] = "toggle-fullscreen",
      ["<M-w>"] = "toggle-preview-wrap",
      ["<M-p>"] = "toggle-preview",
      ["<C-f>"] = "preview-page-down",
      ["<C-b>"] = "preview-page-up",
    },
    fzf = {
      true,
      ["ctrl-f"] = "preview-page-down",
      ["ctrl-b"] = "preview-page-up",
    },
  },
  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --hidden -e",
  },
})

local function hipatterns()
  local hip = require("mini.hipatterns")
  local matches, entries = {}, {}

  for _, bufnr in ipairs(hip.get_enabled_buffers()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      name = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~:.")
      for _, match in ipairs(hip.get_matches(bufnr)) do
        local line = vim.api.nvim_buf_get_lines(bufnr, match.lnum - 1, match.lnum, false)[1] or ""
        matches[#matches + 1] = match
        entries[#entries + 1] = string.format(
          "%d\t%s  %s:%d:%d  %s",
          #matches,
          match.highlighter,
          name,
          match.lnum,
          match.col,
          line:gsub("%s+$", "")
        )
      end
    end
  end

  local previewer = require("fzf-lua.previewer.builtin").buffer_or_file:extend()
  function previewer:parse_entry(entry)
    local match = matches[tonumber(entry:match("^(%d+)\t"))]
    if not match then
      return {}
    end
    return {
      bufnr = match.bufnr,
      path = vim.api.nvim_buf_get_name(match.bufnr),
      line = match.lnum,
      col = match.col,
      tick = vim.b[match.bufnr].changedtick,
    }
  end

  fzf.fzf_exec(entries, {
    prompt = "Hipatterns> ",
    previewer = previewer,
    fzf_opts = { ["--delimiter"] = "\t", ["--with-nth"] = "2.." },
    actions = {
      ["enter"] = function(selected)
        local match = matches[tonumber(selected[1]:match("^(%d+)\t"))]
        if not match or not vim.api.nvim_buf_is_valid(match.bufnr) then
          return
        end
        vim.api.nvim_set_current_buf(match.bufnr)
        vim.api.nvim_win_set_cursor(0, { match.lnum, match.col - 1 })
      end,
    },
  })
end

local map = require("core.keymap")

map("n", "<leader>pr", fzf.resume, "Pick: resume")
map("n", "<leader>pf", fzf.files, "Pick: find files")
map("n", "<leader>pg", fzf.live_grep, "Pick: find inside files with grep live")
map("n", "<leader>pb", fzf.buffers, "Pick: find buffers")
map("n", "<leader>pd", fzf.diagnostics_workspace, "Pick: find diagnostic")
map("n", "<leader>ps", fzf.command_history, "Pick: find command history")
map("n", "<leader>pp", hipatterns, "Pick: find hipatterns")
map("n", "<leader>pk", fzf.keymaps, "Pick: find keymaps")
map("n", '<leader>p"', fzf.registers, "Pick: find registers")
map("n", "<leader>ph", fzf.helptags, "Pick: find help")

map("n", "<leader>plc", fzf.lsp_declarations, "Pick: find lsp declaration")
map("n", "<leader>pld", fzf.lsp_definitions, "Pick: find lsp definition")
map("n", "<leader>pls", fzf.lsp_document_symbols, "Pick: find lsp document symbol")
map("n", "<leader>pli", fzf.lsp_implementations, "Pick: find lsp implementation")
map("n", "<leader>plr", fzf.lsp_references, "Pick: find lsp references")
map("n", "<leader>plt", fzf.lsp_typedefs, "Pick: find lsp type definition")
map("n", "<leader>plS", fzf.lsp_workspace_symbols, "Pick: find lsp workspace symbol")
