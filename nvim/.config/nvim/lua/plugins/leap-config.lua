local map = require("core.keymap")

map({ "n", "x", "o" }, "<leader>jf", "<Plug>(leap-forward)", "jump: leap forward")
map({ "n", "x", "o" }, "<leader>jb", "<Plug>(leap-backward)", "jump: leap backward")
