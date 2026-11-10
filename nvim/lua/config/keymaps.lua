-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Insert-mode line editing that matches the rest of the desktop (see ~/.config/hypr/line-editing.lua).
-- Hyprland passes these chords to terminals unchanged, so Neovim has to give them the desktop meaning.
-- Deletes don't touch any register (so not the clipboard either), and start a new undo step first so
-- `u` brings back only what was deleted.
local function imap(keys, rhs, desc)
  for _, key in ipairs(keys) do
    vim.keymap.set("i", key, rhs, { desc = desc })
  end
end
imap({ "<C-a>" }, "<Home>", "Jump to start of line")
imap({ "<C-e>" }, "<End>", "Jump to end of line") -- blink.cmp still closes its menu first when it's open
-- Edits the line directly: <C-o> would step the cursor back off the end of the line and miss a character.
local function delete_line_part(to_end)
  return function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.o.undolevels = vim.o.undolevels -- starts a new undo step, like <C-g>u
    if to_end then
      vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, #vim.api.nvim_get_current_line(), {})
    else
      vim.api.nvim_buf_set_text(0, row - 1, 0, row - 1, col, {})
      vim.api.nvim_win_set_cursor(0, { row, 0 })
    end
  end
end
imap({ "<C-u>" }, delete_line_part(false), "Delete to start of line")
imap({ "<C-k>" }, delete_line_part(true), "Delete to end of line")
-- SUPER + Z reaches terminals as CTRL + SHIFT + -, which Neovim reads as any of these depending on the encoding.
imap({ "<C-_>", "<C-S-_>", "<C-S-->" }, "<C-o>u", "Undo")
-- SUPER + SHIFT + Z reaches terminals as CTRL + SHIFT + Z (Ghostty sends it as CSI 122;6u).
imap({ "<C-S-z>" }, "<C-o><C-r>", "Redo")

-- Ctrl+Backspace deletes the previous word, as in zsh and the rest of the desktop.
-- Ghostty sends it as <C-BS> or ^H (<C-h>) depending on the keyboard protocol in use.
-- In insert mode, start a new undo step first (as Neovim's own <C-w> does), so `u` restores the word.
for _, key in ipairs({ "<C-BS>", "<C-h>" }) do
  vim.keymap.set("i", key, "<C-g>u<C-w>", { desc = "Delete previous word" })
  vim.keymap.set("c", key, "<C-w>", { desc = "Delete previous word" })
end
