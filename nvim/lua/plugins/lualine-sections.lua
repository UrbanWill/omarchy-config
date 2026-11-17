-- A quieter right side of the status line: only how far through the file you are (e.g. "47%").
-- Dropped from LazyVim's defaults: the last keys typed, the plugin-update count, line:column and
-- the clock. Kept, as they only show when they matter: profiler, macro recording, debugger, git diff.
-- lualine_x is LazyVim's list minus those two entries, so compare it after LazyVim updates.
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
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
