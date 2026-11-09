-- Folders the projects picker (`Space f p`) scans for repos.
-- ~/Work groups repos one level down (~/Work/talisman/signet), so each group is listed.
local dev = { "~/Projects", "~/Work" }
vim.list_extend(dev, vim.fn.glob("~/Work/*/", false, true))

local home = vim.env.HOME
local roots = {
  { prefix = home .. "/Projects/", tag = "Projects", hl = "DiagnosticInfo" },
  { prefix = home .. "/Work/", tag = "Work", hl = "DiagnosticWarn" },
}

-- Row: "<tag>  <group/>name", e.g. "Work      talisman/signet".
-- Recent projects outside both roots show as "Other" with their ~ path.
local function format(item)
  local path = vim.fs.normalize(item.file):gsub("/$", "")
  local tag, hl, rel = "Other", "Comment", vim.fn.fnamemodify(path, ":~")
  for _, root in ipairs(roots) do
    if vim.startswith(path, root.prefix) then
      tag, hl, rel = root.tag, root.hl, path:sub(#root.prefix + 1)
      break
    end
  end
  local parent, name = rel:match("^(.*/)([^/]+)$")
  return {
    { ("%-10s"):format(tag), hl },
    { parent or "", "SnacksPickerDir" },
    { name or rel, "SnacksPickerDirectory" },
  }
end

return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        projects = { dev = dev, format = format },
      },
    },
  },
}
