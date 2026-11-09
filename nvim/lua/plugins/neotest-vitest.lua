-- Vitest runner for the TypeScript repos; LazyVim ships no Vitest adapter.
return {
  "nvim-neotest/neotest",
  dependencies = { "marilari88/neotest-vitest" },
  opts = {
    adapters = {
      ["neotest-vitest"] = {
        -- talisman has 16 vitest configs; never scan into installed packages
        filter_dir = function(name)
          return name ~= "node_modules"
        end,
      },
    },
  },
}
