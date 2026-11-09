-- Octo and the snacks Git Stash picker both claim `Space g S`, and which one wins
-- changes between startups. Keep Git Stash there and move Octo's search to `Space g O`.
return {
  "pwntester/octo.nvim",
  keys = {
    { "<leader>gS", false },
    { "<leader>gO", "<cmd>Octo search<CR>", desc = "Search (Octo)" },
  },
}
