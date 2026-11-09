-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function() vim.b.autoformat = true end,
})

-- `nvim .` (Omarchy's `n` with no args) leaves an empty [No Name] buffer behind once neo-tree
-- takes over the directory; drop it as soon as a real file is opened.
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(args)
    if vim.api.nvim_buf_get_name(args.buf) == "" or vim.bo[args.buf].buftype ~= "" then
      return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if
        buf ~= args.buf
        and vim.bo[buf].buflisted
        and vim.bo[buf].buftype == ""
        and vim.api.nvim_buf_get_name(buf) == ""
        and not vim.bo[buf].modified
        and vim.api.nvim_buf_line_count(buf) == 1
        and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
        and #vim.fn.win_findbuf(buf) == 0
      then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) and #vim.fn.win_findbuf(buf) == 0 then
            pcall(vim.api.nvim_buf_delete, buf, {})
          end
        end)
      end
    end
  end,
})

