local cmdline = require("tiny-cmdline")

cmdline.setup({
  on_reposition = cmdline.adapters.blink,
})
