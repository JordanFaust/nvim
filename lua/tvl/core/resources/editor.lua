local util = require("tvl.util")
local icons = require("tvl.core.icons")

return {
  {
    -- "loctvl842/neo-tree.nvim",
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Neotree",
    config = function() require("tvl.config.neo-tree") end,
  },

  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false,
    dependencies = {
      "JordanFaust/project.nvim",
    },
    opts = {
      defaults = {
        prompt_title = false,
        prompt_prefix = "   ",
        -- selection_caret = "  ",
        selection_caret = "  ",
        -- entry_prefix = "   ",
        path_display = function(_, path)
          local filename = path:gsub(vim.pesc(vim.loop.cwd()) .. '/', ''):gsub(vim.pesc(vim.fn.expand '$HOME'), '~')
          local tail = require('telescope.utils').path_tail(filename)
          local folder = vim.fn.fnamemodify(filename, ':h')
          if folder == '.' then
            return tail
          end

          return string.format('%s  —  %s', tail, folder)
        end,
        borderchars = {
          prompt = util.generate_borderchars(
            "thick",
            nil,
            { top = "█", top_left = "█", left = "█", right = " ", top_right = " ", bottom_right = " " }
          ),
          results = util.generate_borderchars(
            "thick",
            nil,
            { top = "█", top_left = "█", right = " ", top_right = " ", bottom_right = " " }
          ),
          preview = util.generate_borderchars("thick", nil, { top = "█", top_left = "█", top_right = "█" }),
        },
        -- dynamic_preview_title = true,
        hl_result_eol = true,
        sorting_strategy = "ascending",
        file_ignore_patterns = {
          ".git/",
          "target/",
          "docs/",
          "vendor/*",
          "%.lock",
          "__pycache__/*",
          "%.sqlite3",
          "%.ipynb",
          "node_modules/*",
          -- "%.jpg",
          -- "%.jpeg",
          -- "%.png",
          "%.svg",
          "%.otf",
          "%.ttf",
          "%.webp",
          ".dart_tool/",
          ".github/",
          ".gradle/",
          ".idea/",
          ".settings/",
          ".vscode/",
          "__pycache__/",
          "build/",
          "gradle/",
          "node_modules/",
          "%.pdb",
          "%.dll",
          "%.class",
          "%.exe",
          "%.cache",
          "%.ico",
          "%.pdf",
          "%.dylib",
          "%.jar",
          "%.docx",
          "%.met",
          "smalljre_*/*",
          ".vale/",
          "%.burp",
          "%.mp4",
          "%.mkv",
          "%.rar",
          "%.zip",
          "%.7z",
          "%.tar",
          "%.bz2",
          "%.epub",
          "%.flac",
          "%.tar.gz",
        },
        results_title = false,
        layout_config = {
          horizontal = {
            prompt_position = "bottom",
            -- preview_width = 0.55,
            -- results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          -- width = 0.87,
          -- height = 0.80,
          -- preview_cutoff = 120,
        },
        pickers = {
          oldfiles = {
            prompt_title = false,
            sort_lastused = true,
            cwd_only = true,
          },
          find_files = {
            prompt_title = false,
            results_title = false,
            hidden = true,
            cwd_only = true,
          },
        },
      },
    },
    config = function(_, opts)
      local actions = require("telescope.actions")
      local layout_strategies = require('telescope.pickers.layout_strategies')
      -- Add an extra line between the prompt and results so that the theme looks OK
      local original_center = layout_strategies.center
      layout_strategies.center = function(picker, columns, lines, layout_config)
        local res = original_center(picker, columns, lines, layout_config)

        -- Move results down one line so that the prompt bottom border is visible
        res.results.line = res.results.line + 1

        return res
      end

      local original_horizontal = layout_strategies.horizontal
      layout_strategies.horizontal = function(picker, columns, lines, layout_config)
        local layout = original_horizontal(picker, columns, lines, layout_config)

        if layout and layout.prompt ~= nil then
          layout.prompt.title = ''
        end
        if layout and layout.results ~= nil then
          layout.results.title = ''
        end
        if layout and layout.preview ~= nil then
          layout.preview.title = ''
        end

        return layout
      end

      opts.defaults.mappings = {
        i = {
          ["<C-g>"] = actions.close,
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,

          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,

          ["<Down>"] = actions.move_selection_next,
          ["<Up>"] = actions.move_selection_previous,

          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-v>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,

          ["<C-u>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,

          ["<PageUp>"] = actions.results_scrolling_up,
          ["<PageDown>"] = actions.results_scrolling_down,

          ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          ["<C-l>"] = actions.complete_tag,
          ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
        },

        n = {
          ["<esc>"] = actions.close,
          ["<C-g>"] = actions.close,
          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-v>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,

          ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

          ["j"] = actions.move_selection_next,
          ["k"] = actions.move_selection_previous,
          ["H"] = actions.move_to_top,
          ["M"] = actions.move_to_middle,
          ["L"] = actions.move_to_bottom,

          ["<Down>"] = actions.move_selection_next,
          ["<Up>"] = actions.move_selection_previous,
          ["gg"] = actions.move_to_top,
          ["G"] = actions.move_to_bottom,

          ["<C-u>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,

          ["<PageUp>"] = actions.results_scrolling_up,
          ["<PageDown>"] = actions.results_scrolling_down,

          ["?"] = actions.which_key,
        },
      }
      require("telescope").setup(opts)
      require("telescope").load_extension("noice")
      require('telescope').load_extension 'notify'
    end,
  },

  {
    "folke/which-key.nvim",
    config = function() require("tvl.config.whichkey") end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = icons.gitsigns.add },
        change = { text = icons.gitsigns.change },
        delete = { text = icons.gitsigns.delete },
        topdelhfe = { text = icons.gitsigns.topdelhfe },
        changedelete = { text = icons.gitsigns.changedelete },
        untracked = { text = icons.gitsigns.untracked },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300
      },
      current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
      preview_config = {
        border = { "▄", "▄", "▄", "█", "▀", "▀", "▀", "█" }, -- [ top top top - right - bottom bottom bottom - left ]
      }
    },
  },

  -- references
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = { delay = 200 },
    config = function(_, opts)
      require("illuminate").configure(opts)

      local function map(key, dir, buffer)
        vim.keymap.set("n", key, function()
          require("illuminate")["goto_" .. dir .. "_reference"](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
      end

      map("]]", "next")
      map("[[", "prev")

      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map("]]", "next", buffer)
          map("[[", "prev", buffer)
        end,
      })
    end,
    keys = {
      { "]]", desc = "Next Reference" },
      { "[[", desc = "Prev Reference" },
    },
  },

  -- This branch is required to get the neovim-session-manager integration working
  {
    "JordanFaust/project.nvim",
    branch = "main",
    opts = {
      on_config_done = nil,
      manual_mode = false,

      detection_methods = { "pattern" },

      ---@usage patterns used to detect root dir, when **"pattern"** is in detection_methods
      patterns = {
        ".git",
        "_darcs",
        ".hg",
        ".bzr",
        ".svn",
        -- "package.json"
      },

      exclude_dirs = {
        "~/.local/share/nvim/*"
      },

      show_hidden = false,
      silent_chdir = true,
      ignore_lsp = {},

      -- scope_chdir = 'tab',

      session_autoload = true,
      datapath = vim.fn.stdpath("data"),
    },
    config = function(_, opts)
      require("project_nvim").setup(opts)

      local tele_status_ok, telescope = pcall(require, "telescope")
      if not tele_status_ok then return end

      telescope.load_extension("projects")
    end,
  },

  {
    "Shatur/neovim-session-manager",
    config = function()
      require("session_manager").setup({
        -- sessions_dir = Path:new(vim.fn.stdpath('data'), 'sessions'), -- The directory where the session files will be saved.
        path_replacer = '__',                                                    -- The character to which the path separator will be replaced for session files.
        colon_replacer = '++',                                                   -- The character to which the colon symbol will be replaced for session files.
        autoload_mode = require('session_manager.config').AutoloadMode.Disabled, -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
        autosave_last_session = true,                                            -- Automatically save last session on exit and on session switch.
        autosave_ignore_not_normal = true,                                       -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
        autosave_ignore_dirs = {},                                               -- A list of directories where the session will not be autosaved.
        autosave_ignore_filetypes = {                                            -- All buffers of these file types will be closed before the session is saved.
          "gitcommit",
          "dashboard"
        },
        autosave_ignore_buftypes = {},    -- All buffers of these bufer types will be closed before the session is saved.
        autosave_only_in_session = false, -- Always autosaves session. If true, only autosaves after a session is active.
        max_path_length = 80,             -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
      })
    end,
  },

  -- {
  --   "rmagatti/auto-session",
  --   opts = {
  --     log_level = "debug",
  --
  --     auto_save_enabled = true,
  --     auto_session_enable = true,
  --
  --     auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/", "~/.local/share/nvim" },
  --     auto_session_use_git_branch = false,
  --     auto_session_enable_last_session = false,
  --
  --     cwd_change_handling = {
  --       restore_upcoming_session = true, -- already the default, no need to specify like this, only here as an example
  --       pre_cwd_changed_hook = nil, -- already the default, no need to specify like this, only here as an example
  --       -- post_cwd_changed_hook = function() -- example refreshing the lualine status line _after_ the cwd changes
  --       --   require("lualine").refresh() -- refresh lualine so the new session name is displayed in the status bar
  --       -- end,
  --     },
  --
  --     -- ⚠️ This will only work if Telescope.nvim is installed
  --     -- The following are already the default values, no need to provide them if these are already the settings you want.
  --     session_lens = {
  --       -- If load_on_setup is set to false, one needs to eventually call `require("auto-session").setup_session_lens()` if they want to use session-lens.
  --       load_on_setup = true,
  --       prompt_title = "Projects",
  --       theme_conf = { border = true },
  --       previewer = false,
  --     },
  --   },
  -- },

  {
    "kevinhwang91/nvim-ufo",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "kevinhwang91/promise-async", event = "BufReadPost" },
    opts = {
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = ("  … %d "):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end,
      open_fold_hl_timeout = 0,
    },
    keys = {
      { "fd", "zd", desc = "Delete fold under cursor" },
      { "fo", "zo", desc = "Open fold under cursor" },
      { "fO", "zO", desc = "Open all folds under cursor" },
      { "fc", "zC", desc = "Close all folds under cursor" },
      { "fa", "za", desc = "Toggle fold under cursor" },
      { "fA", "zA", desc = "Toggle all folds under cursor" },
      { "fv", "zv", desc = "Show cursor line" },
      {
        "fM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
      {
        "fR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      { "fm", "zm", desc = "Fold more" },
      { "fr", "zr", desc = "Fold less" },
      { "fx", "zx", desc = "Update folds" },
      { "fz", "zz", desc = "Center this line" },
      { "ft", "zt", desc = "Top this line" },
      { "fb", "zb", desc = "Bottom this line" },
      { "fg", "zg", desc = "Add word to spell list" },
      { "fw", "zw", desc = "Mark word as bad/misspelling" },
      { "fe", "ze", desc = "Right this line" },
      { "fE", "zE", desc = "Delete all folds in current buffer" },
      { "fs", "zs", desc = "Left this line" },
      { "fH", "zH", desc = "Half screen to the left" },
      { "fL", "zL", desc = "Half screen to the right" },
    },
  },

  {
    "luukvbaal/statuscol.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        relculright = false,
        ft_ignore = { "neo-tree" },
        segments = {
          {
            -- line number
            text = { " ", builtin.lnumfunc },
            condition = { true, builtin.not_empty },
            click = "v:lua.ScLa",
          },
          { text = { "%s" },                  click = "v:lua.ScSa" }, -- Sign
          { text = { builtin.foldfunc, " " }, click = "v:lua.ScFa" }, -- Fold
        },
      })
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        callback = function()
          if vim.bo.filetype == "neo-tree" then
            vim.opt_local.statuscolumn = ""
          end
        end,
      })
    end,
  },
}
