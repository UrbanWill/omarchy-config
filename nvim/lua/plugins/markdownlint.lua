local base_config_path = vim.fn.stdpath("config") .. "/.markdownlint-cli2.yaml"

-- No diagnostics at all in markdown buffers (covers marksman's LSP warnings too).
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx" },
  callback = function(args)
    vim.diagnostic.enable(false, { bufnr = args.buf })
  end,
})

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      -- The markdown extra registers markdownlint-cli2; drop it.
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = nil
      opts.linters_by_ft["markdown.mdx"] = nil
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdownlint-cli2"] = { prepend_args = { "--config", base_config_path } },
      },
    },
  },
}
