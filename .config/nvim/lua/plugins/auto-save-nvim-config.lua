
vim.pack.add({
	{ src = "https://github.com/okuuva/auto-save.nvim" },
})


local excluded_filetypes = {
	-- this one is especially useful if you use neovim as a commit message editor
	"gitcommit",
	-- most of these are usually set to non-modifiable, which prevents autosaving
	-- by default, but it doesn't hurt to be extra safe.
	"NvimTree",
	"Outline",
	"TelescopePrompt",
	"alpha",
	"dashboard",
	"lazygit",
	"neo-tree",
	"oil",
	"prompt",
	"toggleterm",
}

local excluded_filenames = {
	"do-not-autosave-me.lua",
}

local function save_condition(buf)
	if
		vim.tbl_contains(excluded_filetypes, vim.fn.getbufvar(buf, "&filetype"))
		or vim.tbl_contains(excluded_filenames, vim.fn.expand("%:t"))
	then
		return false
	end
	return true
end

require("auto-save").setup({
  trigger_events = {
    immediate_save = {},
  },
  condition = save_condition,

	debounce_delay = 3000,
})

vim.keymap.set("n", "<leader>ast", ":ASToggle<CR>",
  { noremap = true, silent = true, desc = "auto-save: toggle", })

-- see message when toggle
local augroup = vim.api.nvim_create_augroup("auto-save", {})

vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "AutoSaveEnable",
  callback = function(opts)
    vim.notify(
      "enabled",
      vim.log.levels.INFO,
      { title = "auto-save", }
    )
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "AutoSaveDisable",
  callback = function(opts)
    vim.notify(
      "disabled",
      vim.log.levels.INFO,
      { title = "auto-save", }
    )
  end,
})

