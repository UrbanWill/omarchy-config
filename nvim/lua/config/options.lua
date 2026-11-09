-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false
vim.g.autoformat = false

-- TypeScript 7's native server; the work repos pin TS 7, which vtsls can't load
vim.g.lazyvim_ts_lsp = "tsc"
-- Prettier only where the repo has a Prettier config, so Biome repos get Biome alone
vim.g.lazyvim_prettier_needs_config = true

-- Neovim types compose files as plain yaml; the compose language server only attaches to this filetype
vim.filetype.add({
  pattern = {
    [".*/docker%-compose%.ya?ml"] = "yaml.docker-compose",
    [".*/docker%-compose%.[%w%-_.]+%.ya?ml"] = "yaml.docker-compose",
    [".*/compose%.ya?ml"] = "yaml.docker-compose",
    [".*/compose%.[%w%-_.]+%.ya?ml"] = "yaml.docker-compose",
  },
})

-- Terminal tab title: "<project folder> - nvim", e.g. "tokio-lessons - nvim"
vim.opt.title = true
vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')} - nvim"
