-- Inlay hints are on or off for every buffer at once, toggled with <leader>uh (lua/config/keymaps.lua).
-- LazyVim turns them on per buffer as each language server attaches, which would bring them back in
-- every newly opened file after a global "off". So that is switched off, and Neovim's global state,
-- which new buffers inherit, decides instead.
return {
  "neovim/nvim-lspconfig",
  init = function()
    vim.lsp.inlay_hint.enable(true)
  end,
  opts = {
    inlay_hints = { enabled = false },
  },
}
