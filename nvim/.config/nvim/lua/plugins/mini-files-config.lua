local files = require("mini.files")

files.setup({
  options = {
    permanent_delete = false,
    use_as_default_explorer = false,
  },
  windows = { width_preview = 60 },
})

local show_hidden = true
local preview = false
local show_all = function()
  return true
end
local hide_dotfiles = function(entry)
  return not vim.startswith(entry.name, ".")
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerOpen",
  callback = function()
    show_hidden = true
    preview = false
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  callback = function(args)
    local buffer = args.data.buf_id

    vim.keymap.set("n", "g.", function()
      show_hidden = not show_hidden
      files.refresh({ content = { filter = show_hidden and show_all or hide_dotfiles } })
    end, { buffer = buffer, desc = "Toggle hidden files" })

    vim.keymap.set("n", "gp", function()
      preview = not preview
      files.refresh({ windows = { preview = preview } })
    end, { buffer = buffer, desc = "Toggle preview" })

    vim.keymap.set("n", "gy", function()
      local entry = files.get_fs_entry()
      if entry then
        vim.fn.setreg(vim.v.register, entry.path)
      end
    end, { buffer = buffer, desc = "Yank path" })
  end,
})

require("core.keymap")("n", "<leader>mf", function()
  if files.close() ~= nil then
    return
  end

  local path = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  files.open(path ~= "" and path or nil, false)
end, "mini.files: toggle")
