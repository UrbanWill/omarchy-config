-- A quieter right side of the status line: only how far through the file you are (e.g. "47%").
-- Dropped from LazyVim's defaults: the last keys typed, the plugin-update count, line:column and
-- the clock. Kept, as they only show when they matter: profiler, macro recording, debugger, git diff.
-- lualine_x is LazyVim's list minus those two entries, so compare it after LazyVim updates.
--
-- The status line itself only shows while a terminal window is open (e.g. the Ctrl+/ one), and
-- the bottom row is gone otherwise. lualine turns it back on (laststatus=3) on load and on every
-- colorscheme change, so this re-checks after those as well as whenever windows change.
local function sync_statusline()
  local has_terminal = false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then
      has_terminal = true
      break
    end
  end
  local want = has_terminal and 3 or 0
  if vim.o.laststatus ~= want then
    vim.o.laststatus = want
  end
end

return {
  "nvim-lualine/lualine.nvim",
  -- Not `init`: lazy.nvim replaces a parent spec's `init` instead of merging it, which would drop LazyVim's.
  opts = function(_, opts)
    -- scheduled, so it runs after lualine's setup and handlers, and after a closing window is gone
    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed", "BufWinEnter", "TermOpen", "TermClose", "TabEnter", "ColorScheme" }, {
      group = vim.api.nvim_create_augroup("user_statusline_with_terminal", {}),
      callback = function()
        vim.schedule(sync_statusline)
      end,
    })
    vim.schedule(sync_statusline)

    local icons = LazyVim.config.icons
    opts.sections.lualine_x = {
      Snacks.profiler.status(),
      -- stylua: ignore
      {
        function() return require("noice").api.status.mode.get() end,
        cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
        color = function() return { fg = Snacks.util.color("Constant") } end,
      },
      -- stylua: ignore
      {
        function() return "  " .. require("dap").status() end,
        cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
        color = function() return { fg = Snacks.util.color("Debug") } end,
      },
      {
        "diff",
        symbols = {
          added = icons.git.added,
          modified = icons.git.modified,
          removed = icons.git.removed,
        },
        source = function()
          local gitsigns = vim.b.gitsigns_status_dict
          if gitsigns then
            return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
          end
        end,
      },
    }
    opts.sections.lualine_y = { "progress" }
    opts.sections.lualine_z = {}
  end,
}
