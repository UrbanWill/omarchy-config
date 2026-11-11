return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    {
      "<leader>gv",
      function()
        if next(require("diffview.lib").views) then
          vim.cmd("DiffviewClose")
        else
          vim.cmd("DiffviewOpen")
        end
      end,
      desc = "Diffview Toggle",
    },
    { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
  },
}
