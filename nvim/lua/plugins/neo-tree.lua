-- Show dotfiles and git-ignored files in the tree by default (dimmed). `H` still hides them.
-- The root shows only the project folder's name ("rust-bittensor-indexer"), as Zed does, not its full path.
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
      },
      components = {
        name = function(config, node, state)
          local result = require("neo-tree.sources.common.components").name(config, node, state)
          if node:get_depth() == 1 and node.type ~= "message" then
            -- keep anything neo-tree appends after the name (sort arrow, padding)
            result.text = vim.fn.fnamemodify(node.path, ":t") .. result.text:sub(#node.name + 1)
          end
          return result
        end,
      },
    },
  },
}
