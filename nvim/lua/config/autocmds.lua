-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Easier-to-read code with any theme: no italics (keywords, comments) and no bold types. Markdown
-- emphasis keeps its italic, since there it is part of the text. Runs again whenever a colorscheme
-- loads, so it survives Omarchy theme switches. Linked groups follow their target, so only groups
-- that set their own attributes are changed. Module paths (`bt_domain` in `use bt_domain::…`) take the
-- plain text color, as in Zed, instead of sharing the `use`/`mod` keyword color some themes give them.
local function plain_code_styles()
  local text = { fg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg }
  vim.api.nvim_set_hl(0, "@module", text)
  vim.api.nvim_set_hl(0, "@lsp.type.namespace", text)
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if not hl.link then
      local is_markup = name:find("^@markup") ~= nil
      local is_type = name == "Type" or name:find("^@type") ~= nil or name:find("^@lsp%.type%.") ~= nil
      local changed = false
      if hl.italic and not is_markup then
        hl.italic, changed = nil, true
      end
      if hl.bold and is_type then
        hl.bold, changed = nil, true
      end
      if changed then
        vim.api.nvim_set_hl(0, name, hl)
      end
    end
  end
end
plain_code_styles()
vim.api.nvim_create_autocmd("ColorScheme", { callback = plain_code_styles })

-- A line at the top of each file window with the file's path from the project root
-- (e.g. "crates/chain/src/lib.rs"), like Zed. Set per window, so the file tree, terminals
-- and other special windows don't get an empty bar.
local function update_winbar(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local name = vim.api.nvim_buf_get_name(buf)
  local is_file = vim.bo[buf].buftype == "" and name ~= "" and vim.api.nvim_win_get_config(win).relative == ""
  vim.wo[win].winbar = is_file and " " .. vim.fn.fnamemodify(name, ":~:."):gsub("%%", "%%%%") or ""
end
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufFilePost" }, {
  callback = function()
    update_winbar(vim.api.nvim_get_current_win())
  end,
})
local function update_all_winbars()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    update_winbar(win)
  end
end
-- this file loads after startup, so cover a file opened from the command line (`nvim lib.rs`)
update_all_winbars()
-- Faded like Zed's path: halfway between the theme's text and comment colors, no background.
local function winbar_colors()
  local text = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg
  local muted = vim.api.nvim_get_hl(0, { name = "Comment", link = false }).fg
  if not (text and muted) then
    return
  end
  local mixed = 0
  for _, shift in ipairs({ 16, 8, 0 }) do
    local a, b = bit.band(bit.rshift(text, shift), 0xff), bit.band(bit.rshift(muted, shift), 0xff)
    mixed = mixed + bit.lshift(math.floor((a + b) / 2), shift)
  end
  vim.api.nvim_set_hl(0, "WinBar", { fg = mixed })
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = mixed })
end
winbar_colors()
vim.api.nvim_create_autocmd("ColorScheme", { callback = winbar_colors })
-- paths are relative to the working directory, so redo every window when it changes
vim.api.nvim_create_autocmd("DirChanged", { callback = update_all_winbars })

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

