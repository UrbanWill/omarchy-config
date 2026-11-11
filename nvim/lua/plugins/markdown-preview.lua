local vscode_mpe_mermaid_version = "12.0.0"

local function run(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()
  if result.code ~= 0 then
    error(("markdown-preview.nvim: `%s` failed\n%s"):format(table.concat(cmd, " "), result.stderr or ""))
  end
  return result.stdout
end

-- The prebuilt server binary segfaults on this system. Without it the plugin
-- falls back to running app/index.js with node.
local function use_node_server(dir)
  run({ "npm", "install", "--no-audit", "--no-fund" }, dir .. "/app")
  run({ "git", "checkout", "--", "app/yarn.lock" }, dir)
  vim.fn.delete(dir .. "/app/bin", "rf")
end

-- lazy.nvim refuses to update a plugin whose tracked files are modified.
local function replace_bundled_mermaid(dir)
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  local tarball = vim.trim(run({ "npm", "pack", "mermaid@" .. vscode_mpe_mermaid_version, "--silent" }, tmp))
  run({ "tar", "xzf", tarball, "package/dist/mermaid.min.js" }, tmp)
  run({ "cp", tmp .. "/package/dist/mermaid.min.js", dir .. "/app/_static/mermaid.min.js" })
  vim.fn.delete(tmp, "rf")
  run({ "git", "update-index", "--skip-worktree", "app/_static/mermaid.min.js" }, dir)
end

return {
  "iamcco/markdown-preview.nvim",
  build = function(plugin)
    use_node_server(plugin.dir)
    replace_bundled_mermaid(plugin.dir)
  end,
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
}
