
-- plugin code begin
local config = {
  highlight = "DiffDelete",
  ignored_filetypes = { "TelescopePrompt", "Trouble", "help", "dashboard" },
  ignore_terminal = true,
  return_cursor = true,
  enabled = true,
}

local whitespace = {}

local function should_highlight()
  if vim.bo.buftype == "nofile" then
    return false
  end

  if config.ignore_terminal and vim.bo.buftype == "terminal" then
    return false
  end

  if vim.tbl_contains(config.ignored_filetypes, vim.bo.filetype) then
    return false
  end

  return true
end

whitespace.highlight = function()
  if not config.enabled then
    whitespace.clear_highlight()
    return
  end

  -- Only highlight in normal/visual modes
  local mode = vim.fn.mode()
  if not (mode == "n" or mode == "v" or mode == "V" or mode == "\22") then
    -- In insert/replace/cmdline modes, remove highlights
    vim.cmd("match")
    return
  end

  if not vim.fn.hlexists(config.highlight) then
    error(string.format("highlight %s does not exist", config.highlight))
  end

  if should_highlight() then
    local command = string.format([[match %s /\s\+$/]], config.highlight)
    vim.cmd(command)
  else
    vim.cmd("match")
  end
end

whitespace.toggle = function()
  config.enabled = not config.enabled
  if config.enabled then
    vim.notify(
      "[trailing‑whitespace] enabled",
      vim.log.levels.INFO,
      { title = "trailing-whitespace", }
    )
    whitespace.highlight()
  else
    vim.notify(
      "[trailing‑whitespace] disabled",
      vim.log.levels.INFO,
      { title = "trailing-whitespace", }
    )
    whitespace.clear_highlight()
  end
end

whitespace.clear_highlight = function()
  vim.cmd("match") -- safe: remove only whitespace highlight
end

whitespace.trim = function()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd([[keeppatterns %substitute/\v\s+$//eg]])
  if config.return_cursor then
    vim.fn.setpos(".", save_cursor)
  end
end

whitespace.setup = function(options)
  config = vim.tbl_extend("force", config, options or {})

  local group = vim.api.nvim_create_augroup("whitespace_nvim", { clear = true })

  local events = { "FileType", "TermOpen", "BufEnter", "UIEnter" }
  for _, event in ipairs(events) do
    vim.api.nvim_create_autocmd(event, {
      group = group,
      pattern = "*",
      callback = whitespace.highlight,
    })
  end

  -- Disable highlights when entering insert/replace/cmdline modes
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    pattern = "*",
    callback = whitespace.clear_highlight,
  })

  -- Re-enable highlights when leaving insert/replace/cmdline modes
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    pattern = "*",
    callback = whitespace.highlight,
  })
end
-- plugin code end


whitespace.setup({
  ignored_filetypes = { 'TelescopePrompt', 'Trouble', 'help', 'dashboard' },
  highlight       = 'DiffDelete',
  ignore_terminal = true,
  return_cursor   = true,
  enabled         = true,
})

vim.keymap.set({ 'n', 'v' }, "<leader>tw", whitespace.toggle, {
  noremap = true, silent  = true,
  desc    = "Toggle Trailing Whitespace Viewer"
})

