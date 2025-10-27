
vim.opt.matchpairs:append("<:>")

-- https://www.reddit.com/r/neovim/comments/1kbz9jf/minipairs_mapping_for_angle_brackets_that_doesnt/
local has_pairs, pairs = pcall(require, "mini.pairs")
if has_pairs then
  pairs.map_buf(0, "i", "<", { action = "open",  pair = "<>", neigh_pattern = "[%a:].", })
  pairs.map_buf(0, "i", ">", { action = "close", pair = "<>", neigh_pattern = "[^\\].", })
end

