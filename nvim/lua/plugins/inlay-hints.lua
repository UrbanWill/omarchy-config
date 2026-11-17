-- Inlay hints are off at startup and shown or hidden for every buffer at once with <leader>uh
-- (lua/config/keymaps.lua). LazyVim turns them on per buffer as each language server attaches,
-- which would bring them back in every newly opened file after a global "off". So that is
-- switched off, and Neovim's global state, which new buffers inherit, decides instead.
return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
  },
}
