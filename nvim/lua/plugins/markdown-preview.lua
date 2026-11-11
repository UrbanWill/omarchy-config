-- Two fixes to markdown-preview.nvim, applied on every install and update:
--
-- 1. The prebuilt server binary it downloads segfaults on this system, so
--    :MarkdownPreview silently does nothing. Without that binary the plugin
--    falls back to running app/index.js with node, which works.
-- 2. It bundles Mermaid 10.2.3, whose flowchart layout differs a lot from
--    newer releases. Replace it with the Mermaid that VS Code's Markdown
--    Preview Enhanced ships, so diagrams look the same in both.
local mermaid_version = "12.0.0"

local function run(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()
  if result.code ~= 0 then
    error(("markdown-preview.nvim: `%s` failed\n%s"):format(table.concat(cmd, " "), result.stderr or ""))
  end
  return result.stdout
end

return {
  "iamcco/markdown-preview.nvim",
  -- The stock toggle keeps a per-buffer "open" flag that closing the browser tab
  -- never clears, so after closing the tab the next press only stops the server.
  -- Decide from what the server reports instead: a page is connected or not.
  keys = {
    {
      "<leader>cp",
      ft = "markdown",
      function()
        if vim.g.mkdp_clients_active == 1 then
          vim.cmd("MarkdownPreviewStop")
        else
          vim.cmd("MarkdownPreview")
        end
      end,
      desc = "Markdown Preview",
    },
  },
  build = function(plugin)
    local app = plugin.dir .. "/app"
    run({ "npm", "install", "--no-audit", "--no-fund" }, app)
    vim.fn.delete(app .. "/bin", "rf")

    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")
    local tarball = vim.trim(run({ "npm", "pack", "mermaid@" .. mermaid_version, "--silent" }, tmp))
    run({ "tar", "xzf", tarball, "package/dist/mermaid.min.js" }, tmp)
    run({ "cp", tmp .. "/package/dist/mermaid.min.js", app .. "/_static/mermaid.min.js" })
    vim.fn.delete(tmp, "rf")
  end,
}
