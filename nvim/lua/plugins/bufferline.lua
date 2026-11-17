-- <leader>b1 … <leader>b9 jump to the buffer at that position in the bufferline, counting from the left,
-- and each tab shows its position so the number to press is always on screen.
local keys = {}
for i = 1, 9 do
  table.insert(keys, { "<leader>b" .. i, "<Cmd>BufferLineGoToBuffer " .. i .. "<CR>", desc = "Go to Buffer " .. i })
end
table.insert(keys, { "<leader>b0", "<Cmd>BufferLineGoToBuffer -1<CR>", desc = "Go to Last Buffer" })

return {
  "akinsho/bufferline.nvim",
  keys = keys,
  opts = function(_, opts)
    -- Only the slant/slope styles draw the current tab's edges with their own highlight (separator_selected);
    -- every other style shares one divider color. So keep the "slope" style but swap its glyphs for thin
    -- vertical bars that meet back to back between tabs. This edits a table inside bufferline, which an update could rename.
    require("bufferline.constants").sep_chars.slope = { "▕", "▏" }

    opts.options = vim.tbl_extend("force", opts.options or {}, {
      numbers = "ordinal",
      indicator = { style = "underline" },
      separator_style = "slope",
      style_preset = require("bufferline").style_preset.no_italic,
      -- apply the colors below even with themes (e.g. tokyonight) that ship their own tab bar colors
      themable = false,
    })
    -- A function, so bufferline works it out again on every colorscheme change.
    local base = opts.highlights
    opts.highlights = function(defaults)
      local hls = vim.tbl_deep_extend("force", defaults.highlights, type(base) == "function" and base(defaults) or base or {})
      -- The current tab stands out as in Zed: every part of it (name, number, icon, close button,
      -- edges…) sits on a tint, the current-line highlight's color. Other tabs stay in muted text.
      for name in pairs(defaults.highlights) do
        if name:find("_selected$") then
          hls[name] = vim.tbl_extend("force", hls[name] or {}, { bg = { attribute = "bg", highlight = "CursorLine" } })
        end
      end
      -- the current tab's edges, in the underline's color (TabLineSel's background)
      hls.separator_selected.fg = { attribute = "bg", highlight = "TabLineSel" }
      -- the other tabs' edges, in the muted color of their names (bufferline's own pick is near-black)
      hls.separator = vim.tbl_extend("force", hls.separator or {}, { fg = { attribute = "fg", highlight = "TabLine" } })
      return hls
    end
  end,
}
