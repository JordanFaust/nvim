---@class util.pick
---@overload fun(command:string, opts?:util.pick.Opts): fun()
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.wrap(...)
  end,
})

---@class util.pick.Opts: table<string, any>
---@field root? boolean
---@field cwd? string
---@field buf? number
---@field show_untracked? boolean

---@class LazyPicker
---@field name string
---@field open fun(command:string, opts?:util.pick.Opts)
---@field commands table<string, string>

---@type LazyPicker?
M.picker = nil

---@param picker LazyPicker
function M.register(picker)
  -- this only happens when using :LazyExtras
  -- so allow to get the full spec
  if vim.v.vim_did_enter == 1 then
    return true
  end

  if M.picker and M.picker.name ~= picker.name then
    CoreUtil.warn(
      "`CoreUtil.pick`: picker already set to `" .. M.picker.name .. "`,\nignoring new picker `" .. picker.name .. "`"
    )
    return false
  end
  M.picker = picker
  return true
end

---@param command? string
---@param opts? util.pick.Opts
function M.open(command, opts)
  if not M.picker then
    return CoreUtil.error("CoreUtil.pick: picker not set")
  end

  command = command ~= "auto" and command or "files"
  opts = opts or {}

  opts = vim.deepcopy(opts)

  if type(opts.cwd) == "boolean" then
    CoreUtil.warn("CoreUtil.pick: opts.cwd should be a string or nil")
    opts.cwd = nil
  end

  if not opts.cwd and opts.root ~= false then
    opts.cwd = CoreUtil.root({ buf = opts.buf })
  end

  command = M.picker.commands[command] or command
  M.picker.open(command, opts)
end

---@param command? string
---@param opts? util.pick.Opts
function M.wrap(command, opts)
  opts = opts or {}
  return function()
    CoreUtil.pick.open(command, vim.deepcopy(opts))
  end
end

function M.config_files()
  return M.wrap("files", { cwd = vim.fn.stdpath("config") })
end

return M
