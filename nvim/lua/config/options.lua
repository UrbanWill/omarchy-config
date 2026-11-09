-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false
vim.g.autoformat = false

-- Terminal tab title: "<project folder> - nvim", e.g. "tokio-lessons - nvim"
vim.opt.title = true
vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')} - nvim"
