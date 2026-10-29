local M = {}

function M.ensure_executable(key, candidates, feature, fallback)
  local override = key and _G.Paths[key]
  if type(override) == "string" and vim.fn.executable(override) == 1 then
    return override
  end
  for _, command in ipairs(candidates) do
    if vim.fn.executable(command) == 1 then
      return command
    end
  end

  vim.notify_once(
    ("%s needs %s%s"):format(
      feature,
      key or table.concat(candidates, " or "),
      fallback and "; using fallback" or "; action stopped"
    ),
    fallback and vim.log.levels.WARN or vim.log.levels.ERROR,
    { title = "External tools" }
  )
  return nil
end

return M
