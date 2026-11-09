-- lspconfig's Tailwind root falls back to `.git` for Tailwind v4, which starts the server in
-- every git repo (signet-backend included). Keep the config-file and package.json checks,
-- drop the `.git` fallback; v4 repos are still found through their `tailwindcss` dependency.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tailwindcss = {
        root_dir = function(bufnr, on_dir)
          local util = require("lspconfig.util")
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local markers = util.insert_package_json({
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.mjs",
            "tailwind.config.ts",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.mjs",
            "postcss.config.ts",
          }, "tailwindcss", fname)
          local root = vim.fs.root(fname, markers)
          if root then
            on_dir(root)
          end
        end,
      },
    },
  },
}
