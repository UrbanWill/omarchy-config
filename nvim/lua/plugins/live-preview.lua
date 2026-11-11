local vscode_mpe_mermaid_version = "12.0.0"

local function run(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()
  if result.code ~= 0 then
    error(("live-preview.nvim: `%s` failed\n%s"):format(table.concat(cmd, " "), result.stderr or ""))
  end
  return result.stdout
end

-- lazy.nvim refuses to update a plugin whose tracked files are modified.
local function replace_bundled_mermaid(dir)
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  local tarball = vim.trim(run({ "npm", "pack", "mermaid@" .. vscode_mpe_mermaid_version, "--silent" }, tmp))
  run({ "tar", "xzf", tarball, "package/dist/mermaid.min.js" }, tmp)
  run({ "cp", tmp .. "/package/dist/mermaid.min.js", dir .. "/static/mermaid/mermaid.min.js" })
  vim.fn.delete(tmp, "rf")
  run({ "git", "update-index", "--skip-worktree", "static/mermaid/mermaid.min.js" }, dir)
end

return {
  -- LazyVim's markdown extra adds it; live-preview.nvim replaces it.
  { "iamcco/markdown-preview.nvim", enabled = false },
  {
    "brianhuster/live-preview.nvim",
    cmd = "LivePreview",
    build = function(plugin)
      replace_bundled_mermaid(plugin.dir)
    end,
    keys = {
      { "<leader>cp", "<cmd>LivePreview start<cr>", ft = "markdown", desc = "Markdown Preview" },
    },
  },
}
