-- Use the Nomic Foundation server instead of LazyVim's default (vscode-solidity-server).
-- The default only compiles with its bundled solc, so a pinned `pragma solidity 0.8.20`
-- stops compilation at the pragma, and switching it to a remote solc crashes it
-- (`solJson.cwrap is not a function`). The Nomic server reads foundry.toml itself.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      solidity_ls = { enabled = false },
      solidity_ls_nomicfoundation = {},
    },
  },
}
