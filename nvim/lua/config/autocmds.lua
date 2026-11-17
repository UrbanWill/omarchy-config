-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, {})
end

-- Easier-to-read code with any theme, reapplied on every colorscheme so it survives Omarchy theme
-- switches: no italics (markdown emphasis keeps its own), no bold types, and module paths
-- (`bt_domain` in `use bt_domain::…`) in the plain text color, as in Zed, instead of the keyword color.
local function plain_code_styles()
  local text = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg
  vim.api.nvim_set_hl(0, "@module", { fg = text })
  vim.api.nvim_set_hl(0, "@lsp.type.namespace", { fg = text })
  -- linked groups follow their target, so only groups that set their own attributes are touched
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if not hl.link then
      if hl.italic and not name:find("^@markup") then
        vim.api.nvim_set_hl(0, name, { italic = false, update = true })
      end
      if hl.bold and (name == "Type" or name:find("^@type") or name:find("^@lsp%.type%.")) then
        vim.api.nvim_set_hl(0, name, { bold = false, update = true })
      end
    end
  end
end
plain_code_styles()
vim.api.nvim_create_autocmd("ColorScheme", { group = augroup("plain_code_styles"), callback = plain_code_styles })

-- Each file window gets a line at the top with its path from the project root
-- ("crates/chain/src/lib.rs"), like Zed. Set per window, so the file tree, terminals and
-- other special windows don't get an empty bar.
local function update_winbar(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local name = vim.api.nvim_buf_get_name(buf)
  local is_file = vim.bo[buf].buftype == "" and name ~= "" and vim.api.nvim_win_get_config(win).relative == ""
  vim.wo[win].winbar = is_file and " " .. vim.fn.fnamemodify(name, ":~:."):gsub("%%", "%%%%") or ""
end
local function update_all_winbars()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    update_winbar(win)
  end
end
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
-- windows opened before this file loaded
update_all_winbars()
winbar_colors()
local winbar = augroup("winbar")
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufFilePost" }, {
  group = winbar,
  callback = function()
    update_winbar(vim.api.nvim_get_current_win())
  end,
})
-- paths are relative to the working directory
vim.api.nvim_create_autocmd("DirChanged", { group = winbar, callback = update_all_winbars })
vim.api.nvim_create_autocmd("ColorScheme", { group = winbar, callback = winbar_colors })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("rust_autoformat"),
  pattern = "rust",
  callback = function() vim.b.autoformat = true end,
})

-- `nvim .` (Omarchy's `n` with no args) leaves an empty [No Name] buffer behind once neo-tree
-- takes over the directory; drop it as soon as a real file is opened.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup("drop_empty_buffer"),
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

