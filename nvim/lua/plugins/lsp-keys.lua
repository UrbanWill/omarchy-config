-- LazyVim maps insert-mode Ctrl+K to signature help in every LSP buffer, which overrides the
-- desktop-style "delete to end of line" in lua/config/keymaps.lua. Signature help stays on `gK`.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ["*"] = {
        keys = {
          { "<c-k>", false, mode = "i" },
        },
      },
    },
  },
}
