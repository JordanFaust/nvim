---@class util.telescope
local M = {}

-- See https://github.com/JoosepAlviste/dotfiles/blob/master/config/nvim/lua/j/pretty_pickers.lua
local telescope_utils = require("telescope.utils")
local make_entry = require("telescope.make_entry")
local plenary_strings = require("plenary.strings")
local devicons = require("nvim-web-devicons")
local entry_display = require("telescope.pickers.entry_display")
-- See https://github.com/JoosepAlviste/dotfiles/blob/master/config/nvim/lua/j/telescope_custom_pickers.lua
local Path = require("plenary.path")
local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local transform_mod = require("telescope.actions.mt").transform_mod
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local os_sep = Path.path.sep
local pickers = require("telescope.pickers")
local scan = require("plenary.scandir")

local file_type_icon_width = plenary_strings.strdisplaywidth(devicons.get_icon("fname", { default = true }))

---Keep track of the active extension and folders for `live_grep`
local live_grep_filters = {
  ---@type nil|string
  extension = nil,
  ---@type nil|string[]
  directories = nil,
}

-- Generates a Grep Search picker but beautified
-- ----------------------------------------------
-- This is a wrapping function used to modify the appearance of pickers that provide Grep Search
-- functionality, mainly because the default one doesn"t look good. It does this by changing the "display()"
-- function that Telescope uses to display each entry in the Picker.
--
--@param (table) picker_and_options - A table with the following format:
--                                   {
--                                      picker = "<pickerName>",
--                                      (optional) options = { ... }
--                                   }
local function pretty_grep_picker(picker_and_options)
  if type(picker_and_options) ~= "table" or picker_and_options.picker == nil then
    print("Incorrect argument format. Correct format is: { picker = ")
    return
  end

  local options = picker_and_options.options or {}

  -- Use Telescope"s existing function to obtain a default "entry_maker" function
  -- ----------------------------------------------------------------------------
  -- INSIGHT: Because calling this function effectively returns an "entry_maker" function that is ready to
  --          handle entry creation, we can later call it to obtain the final entry table, which will
  --          ultimately be used by Telescope to display the entry by executing its "display" key function.
  --          This reduces our work by only having to replace the "display" function in said table instead
  --          of having to manipulate the rest of the data too.
  local original_entry_maker = make_entry.gen_from_vimgrep(options)

  -- INSIGHT: "entry_maker" is the hardcoded name of the option Telescope reads to obtain the function that
  --          will generate each entry.
  -- INSIGHT: The paramenter "line" is the actual data to be displayed by the picker, however, its form is
  --          raw (type "any) and must be transformed into an entry table.
  options.entry_maker = function(line)
    -- Generate the Original Entry table
    local original_entry_table = original_entry_maker(line)

    -- INSIGHT: An "entry display" is an abstract concept that defines the "container" within which data
    --          will be displayed inside the picker, this means that we must define options that define
    --          its dimensions, like, for example, its width.
    local displayer = entry_display.create({
      separator = " ", -- Telescope will use this separator between each entry item
      items = {
        { width = file_type_icon_width },
        { width = nil },
        { width = nil }, -- Maximum path size, keep it short
        { remaining = true },
      },
    })

    -- LIFECYCLE: At this point the "displayer" has been created by the create() method, which has in turn
    --            returned a function. This means that we can now call said function by using the
    --            "displayer" variable and pass it actual entry values so that it will, in turn, output
    --            the entry for display.
    --
    -- INSIGHT: We now have to replace the "display" key in the original entry table to modify the way it
    --          is displayed.
    -- INSIGHT: The "entry" is the same Original Entry Table but is is passed to the "display()" function
    --          later on the program execution, most likely when the actual display is made, which could
    --          be deferred to allow lazy loading.
    --
    -- HELP: Read the "make_entry.lua" file for more info on how all of this works
    original_entry_table.display = function(entry)
      ---- Get File columns data ----
      -------------------------------

      local tail, path_to_display = M.get_path_and_tail(entry.filename)

      local icon, icon_highlight = telescope_utils.get_devicons(tail)

      ---- Format Text for display ----
      ---------------------------------

      -- Add coordinates if required by "options"
      local coordinates = ""

      if not options.disable_coordinates then
        if entry.lnum then
          if entry.col then
            coordinates = string.format("%s:%s", entry.lnum, entry.col)
          else
            coordinates = string.format("%s", entry.lnum)
          end
        end
      end

      -- Encode text if necessary
      local text = options.file_encoding and vim.iconv(entry.text, options.file_encoding, "utf8") or entry.text

      -- INSIGHT: This return value should be a tuple of 2, where the first value is the actual value
      --          and the second one is the highlight information, this will be done by the displayer
      --          internally and return in the correct format.
      return displayer({
        { icon,            icon_highlight },
        tail,
        { coordinates,     "TelescopeResultsComment" },
        { path_to_display, "TelescopeResultsComment" },
        text,
      })
    end

    return original_entry_table
  end

  local picker_functions = {
    ["live_grep"] = function() require("telescope.builtin").live_grep(options) end,
    ["grep_string"] = function() require("telescope.builtin").grep_string(options) end,
    ["find_files"] = function() require("telescope.builtin").find_files(options) end,
    [""] = function() vim.print("Picker was not specified") end,
  }

  -- Finally, check which file picker was requested and open it with its associated options
  local picker = picker_functions[picker_and_options.picker]
  if picker == nil then
    print("Picker is not supported by Pretty Grep Picker")
    return
  end

  picker()
end


---Run `live_grep` with the active filters (extension and folders)
---@param current_input ?string
local function run_live_grep(current_input)
  -- TODO: Resume old one with same options somehow
  pretty_grep_picker({
    picker = "live_grep",
    options = {
      additional_args = live_grep_filters.extension
          and function() return { "-g", "*." .. live_grep_filters.extension } end,
      search_dirs = live_grep_filters.directories,
      default_text = current_input,
    },
  })
end

---Gets the File Path and its Tail (the file name) as a Tuple
---@param file_name string
---@return string, string
function M.get_path_and_tail(file_name)
  local buffer_name_tail = telescope_utils.path_tail(file_name)

  local path_without_tail = require("plenary.strings").truncate(file_name, #file_name - #buffer_name_tail, "")

  local path_to_display = telescope_utils.transform_path({
    path_display = { "truncate" },
  }, path_without_tail)

  return buffer_name_tail, path_to_display
end

M.actions = transform_mod({
  ---Ask for a file extension and open a new `live_grep` filtering by it
  ---@param prompt_bufnr number
  set_extension = function(prompt_bufnr)
    local current_input = action_state.get_current_line()

    vim.ui.input({ prompt = "*." }, function(input)
      if input == nil then return end

      live_grep_filters.extension = input

      actions.close(prompt_bufnr)
      run_live_grep(current_input)
    end)
  end,
  ---Ask the user for a folder and olen a new `live_grep` filtering by it
  ---@param prompt_bufnr number
  set_folders = function(prompt_bufnr)
    local current_input = action_state.get_current_line()

    local data = {}
    scan.scan_dir(vim.loop.cwd(), {
      hidden = true,
      only_dirs = true,
      respect_gitignore = true,
      on_insert = function(entry) table.insert(data, entry .. os_sep) end,
    })
    table.insert(data, 1, "." .. os_sep)

    actions.close(prompt_bufnr)
    pickers
        .new({}, {
          prompt_title = "Folders for Live Grep",
          finder = finders.new_table({ results = data, entry_maker = make_entry.gen_from_file({}) }),
          previewer = conf.file_previewer({}),
          sorter = conf.file_sorter({}),
          attach_mappings = function(prompt_bufnr)
            action_set.select:replace(function()
              local current_picker = action_state.get_current_picker(prompt_bufnr)

              local dirs = {}
              local selections = current_picker:get_multi_selection()
              if vim.tbl_isempty(selections) then
                table.insert(dirs, action_state.get_selected_entry().value)
              else
                for _, selection in ipairs(selections) do
                  table.insert(dirs, selection.value)
                end
              end
              live_grep_filters.directories = dirs

              actions.close(prompt_bufnr)
              run_live_grep(current_input)
            end)
            return true
          end,
        })
        :find()
  end,
})

---Small wrapper over `live_grep` to first reset our active filters
M.live_grep = function()
  live_grep_filters.extension = nil
  live_grep_filters.directories = nil

  run_live_grep()
end

--- Find files with the current input as default text
---@param current_input string
M.find_files = function(current_input)
  pretty_grep_picker({
    picker = "find_files",
    options = {
      -- cwd_only = true,
      search_dirs = nil,
      search_file = nil,
      default_text = current_input or "",
    },
  })
end

return M
