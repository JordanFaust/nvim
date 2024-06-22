return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false, -- last release is way too old and doesn"t work on Windows
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      { "JoosepAlviste/nvim-ts-context-commentstring", dev = false },
    },
    opts = {
      ensure_installed = {
        "bash",
        "cmake",
        "dockerfile",
        -- "help",
        "html",
        "helm",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "go",
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        "python",
        "query",
        "regex",
        "ruby",
        "tsx",
        "typescript",
        "terraform",
        "starlark",
        "vim",
        "yaml",
        "graphql",
        "capnp",
      },
      highlight = { enable = true },
      indent = { enable = true, disable = { "yaml", "python", "html", "ruby" } },
      rainbow = {
        enable = false,
        query = "rainbow-parens",
        disable = { "jsx", "html" },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "HiPhish/nvim-ts-rainbow2",
    event = "BufReadPost",
  },

  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html",
      "javascript",
      "typescript",
      "javascriptreact",
      "typescriptreact",
      "svelte",
      "vue",
      "tsx",
      "jsx",
      "rescript",
      "xml",
      "php",
      "markdown",
      "glimmer",
      "handlebars",
      "hbs",
    },
    opts = {
      enable = true,
      filetypes = {
        "html",
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "svelte",
        "vue",
        "tsx",
        "jsx",
        "rescript",
        "xml",
        "php",
        "markdown",
        "glimmer",
        "handlebars",
        "hbs",
      },
    },
  },

  { "towolf/vim-helm" },
}
