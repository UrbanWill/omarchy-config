-- Needs `mmdc` (pacman: mermaid-cli) and a terminal with the kitty graphics protocol.

local border_cells = 2
local enabled = true

local function is_markdown_window(win)
  return vim.api.nvim_win_get_config(win).relative == ""
    and vim.bo[vim.api.nvim_win_get_buf(win)].filetype:match("^markdown") ~= nil
end

local function redraw_inline_images(buf)
  pcall(vim.api.nvim_exec_autocmds, "BufWinEnter", { group = "snacks.image.inline." .. buf, buffer = buf })
end

-- snacks counts the gutter (line numbers, signs) as available width, which
-- would cut off the right edge. Each image copies these limits when snacks
-- creates it, so images are recreated whenever the limits change.
local function fit_to_window_text_area()
  local win = vim.api.nvim_get_current_win()
  if not is_markdown_window(win) then
    return
  end
  local doc = Snacks.image.config.doc
  local info = vim.fn.getwininfo(win)[1]
  local width, height = info.width - info.textoff, info.height - border_cells
  if doc.max_width == width and doc.max_height == height then
    return
  end
  doc.max_width, doc.max_height = width, height
  local buf = vim.api.nvim_win_get_buf(win)
  Snacks.image.placement.clean(buf)
  redraw_inline_images(buf)
end

-- Inline rendering asks find_visible() which images are on screen and removes
-- any placement it no longer reports. Reporting none while disabled makes
-- snacks remove every image itself, and keeps new buffers empty.
local function gate_inline_rendering()
  local find_visible = Snacks.image.doc.find_visible
  Snacks.image.doc.find_visible = function(buf, cb)
    if not enabled then
      return cb({})
    end
    return find_visible(buf, cb)
  end
end

local function close_hover_on_document_scroll()
  for id in pairs(vim.v.event) do
    local win = tonumber(id)
    if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
      return Snacks.image.doc.hover_close()
    end
  end
end

return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      convert = {
        -- snacks shrinks an image to fit the window but never enlarges it, so
        -- draw diagrams at 4x and let them shrink to the available space.
        mermaid = function()
          local theme = vim.o.background == "light" and "neutral" or "dark"
          return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", theme, "-s", "4" }
        end,
      },
      doc = {
        inline = true,
        -- Mermaid blocks have the image type "chart".
        conceal = function(_, type)
          return type == "math" or type == "chart"
        end,
      },
    },
    styles = {
      -- Its size is set from the image just before it is shown.
      snacks_image = {
        relative = "editor",
        row = function(win)
          return math.max(0, math.floor((vim.o.lines - win.opts.height - border_cells) / 2))
        end,
        col = function(win)
          return math.max(0, math.floor((vim.o.columns - win.opts.width - border_cells) / 2))
        end,
      },
    },
  },
  keys = {
    {
      "<leader>cP",
      function()
        -- snacks copies these limits when it creates the float.
        local doc = Snacks.image.config.doc
        local width, height = doc.max_width, doc.max_height
        doc.max_width, doc.max_height = vim.o.columns - 2 * border_cells, vim.o.lines - 2 * border_cells
        Snacks.image.hover()
        vim.schedule(function()
          doc.max_width, doc.max_height = width, height
        end)
      end,
      ft = "markdown",
      desc = "Diagram/Image Under Cursor (Large)",
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        gate_inline_rendering()
        fit_to_window_text_area()
        vim.api.nvim_create_autocmd({ "VimResized", "WinResized", "WinEnter", "BufWinEnter" }, {
          callback = vim.schedule_wrap(fit_to_window_text_area),
        })
        vim.api.nvim_create_autocmd("WinScrolled", { callback = close_hover_on_document_scroll })
        Snacks.toggle({
          name = "Inline Diagrams",
          get = function()
            return enabled
          end,
          set = function(on)
            enabled = on
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(buf) then
                redraw_inline_images(buf)
              end
            end
          end,
        }):map("<leader>uM")
      end,
    })
  end,
}
