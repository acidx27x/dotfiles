local map = require("core.keymap")
local leap = require("leap")
local clever = require("leap.user").with_traversal_keys

leap.opts.safe_labels = ""

local clever_s = clever("f", "b")
map({ "n", "x", "o" }, "Kf", function()
  leap.leap({ opts = clever_s })
end, "jump: leap forward")
map({ "n", "x", "o" }, "Kb", function()
  leap.leap({ backward = true, opts = clever_s })
end, "jump: leap backward")

local last_ft
local function ft(kwargs)
  leap.leap(vim.tbl_deep_extend("keep", kwargs, {
    inputlen = 1,
    inclusive = true,
    opts = {
      labels = "",
      safe_labels = vim.fn.mode(1):match("no?") and "" or nil,
    },
  }))
  if leap.state["repeat"].inputlen == 1 and leap.state["repeat"].in1 then
    last_ft = leap.state["repeat"]
  end
end

map({ "n", "x", "o" }, "f", function()
  ft({})
end, "jump: find forward")
map({ "n", "x", "o" }, "F", function()
  ft({ backward = true })
end, "jump: find backward")
map({ "n", "x", "o" }, "t", function()
  ft({ offset = { -1 } })
end, "jump: till forward")
map({ "n", "x", "o" }, "T", function()
  ft({ backward = true, offset = { -1 } })
end, "jump: till backward")

local function repeat_ft(reverse)
  if not last_ft then
    return
  end
  local previous = leap.state["repeat"]
  leap.state["repeat"] = last_ft
  local backward = last_ft.backward
  if reverse then
    backward = not backward
  end
  local ok, err = pcall(leap.leap, {
    ["repeat"] = true,
    backward = backward,
    opts = last_ft.opts,
  })
  leap.state["repeat"] = previous
  if not ok then
    error(err)
  end
end
map({ "n", "x", "o" }, ";", function()
  repeat_ft(false)
end, "jump: repeat last find")
map({ "n", "x", "o" }, ",", function()
  repeat_ft(true)
end, "jump: reverse last find")

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("LeapBackdrop", { clear = true }),
  callback = function()
    require("leap.user").set_backdrop_highlight("Comment")
  end,
})
