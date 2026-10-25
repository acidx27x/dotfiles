local defaults = { silent = true }

return function(mode, lhs, rhs, desc, opts)
  local map_opts = vim.tbl_extend("force", defaults, opts or {})
  if desc ~= nil then
    map_opts.desc = desc
  end

  return vim.keymap.set(mode, lhs, rhs, map_opts)
end
