return {
  -- Disable the old dashboard-nvim plugin since we're using snacks dashboard now
  { "nvimdev/dashboard-nvim", enabled = false },

  -- Disabled mason servers that must be managed by nix-darwin (NixOS + macOS)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = { mason = false },
        helm_ls = { mason = false },
        marksman = { mason = false },
      },
    },
  },
}
