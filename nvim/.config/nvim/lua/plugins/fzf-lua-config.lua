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

local function project_markers()
  local rg = require("core.tools").ensure_executable("rg", { "rg" }, "Project marker search")
  if not rg then
    return
  end
  fzf.grep({
    prompt = "Markers> ",
    cwd = vim.fn.getcwd(),
    regex = [[\b(FIXME|ERROR|HACK|WARN|TODO|NOTE|HINT|INFO)\b]],
    cmd = vim.fn.shellescape(rg)
      .. " --glob "
      .. vim.fn.shellescape("!.git")
      .. " "
      .. fzf.config.globals.grep.rg_opts,
  })
end

local map = require("core.keymap")

map("n", "<leader>pr", fzf.resume, "Pick: resume")
map("n", "<leader>pf", fzf.files, "Pick: find files")
map("n", "<leader>pg", fzf.live_grep, "Pick: find inside files with grep live")
map("n", "<leader>pb", fzf.buffers, "Pick: find buffers")
map("n", "<leader>pd", fzf.diagnostics_workspace, "Pick: find diagnostic")
map("n", "<leader>ps", fzf.command_history, "Pick: find command history")
map("n", "<leader>pp", project_markers, "Pick: find project TODO markers")
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
