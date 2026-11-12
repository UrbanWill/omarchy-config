-- <leader>b1 … <leader>b9 jump to the buffer at that position in the bufferline, counting from the left,
-- and each tab shows its position so the number to press is always on screen.
local keys = {}
for i = 1, 9 do
  table.insert(keys, { "<leader>b" .. i, "<Cmd>BufferLineGoToBuffer " .. i .. "<CR>", desc = "Go to Buffer " .. i })
end
table.insert(keys, { "<leader>b0", "<Cmd>BufferLineGoToBuffer -1<CR>", desc = "Go to Last Buffer" })

return {
  "akinsho/bufferline.nvim",
  keys = keys,
  opts = {
    options = {
      numbers = "ordinal",
      indicator = { style = "underline" },
    },
  },
}
