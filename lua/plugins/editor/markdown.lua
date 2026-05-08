return {
  -- Disable the default markdown preview in favor of peek
  { "iamcco/markdown-preview.nvim", enabled = false },

  -- Alternative peek.nvim setup for markdown preview
  {
    "toppair/peek.nvim",
    enabled = function()
      return not vim.env.CODER
    end,
    event = { "VeryLazy" },
    build = "deno task --quiet build:fast",
    opts = {
      -- app = { "firefox", "--new-window" },
      app = "browser",
    },
    cmd = { "PeekOpen", "PeekClose" },
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>PeekOpen<cr>",
        desc = "Markdown Preview",
      },
    },
    config = function(_, opts)
      require("peek").setup(opts)
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },
}
