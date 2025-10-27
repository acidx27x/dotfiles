
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.tabline" },
})


require("mini.tabline").setup({
  show_icons      = true,
  tabpage_section = "right",


  format = function(buf_id, label)
    local suffix = vim.bo[buf_id].modified and "+" or " "

    -- Get buffer number
    local buf_num = buf_id

    -- Get tab number (find which tabpage this buffer belongs to)
    local tab_num = 0
    for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
        local b = vim.api.nvim_win_get_buf(win)
        if b == buf_id then
          tab_num = i
          break
        end
      end
      if tab_num ~= 0 then break end
    end

    local base_label = MiniTabline.default_format(buf_id, label)
    return string.format("▎%s[%d/%d]%s", suffix, tab_num, buf_num, base_label)
  end,
})


vim.opt.showtabline = 2  -- Always show tabline (0=never, 1=when multiple tabs, 2=always)
vim.opt.hidden      = true  -- Allow hidden buffers

