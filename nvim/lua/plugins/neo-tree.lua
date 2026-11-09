-- Show dotfiles and git-ignored files in the tree by default (dimmed). `H` still hides them.
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
      },
    },
  },
}
