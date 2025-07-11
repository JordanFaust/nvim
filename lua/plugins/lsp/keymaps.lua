local M = {}

---@type LazyKeysLspSpec[]|nil
M._keys = nil

---@alias LazyKeysLspSpec LazyKeysSpec|{has?:string|string[], cond?:fun():boolean}
---@alias LazyKeysLsp LazyKeys|{has?:string|string[], cond?:fun():boolean}

---@return LazyKeysLspSpec[]
function M.get()
  if M._keys then
    return M._keys
  end
  local telescope = require("telescope.builtin")
  -- stylua: ignore
  M._keys = {
    { "<leader>cl", "<cmd>LspInfo<cr>",                       desc = "Lsp Info" },
    -- { "gd",         telescope.lsp_definitions,                desc = "Goto Definition" },
    -- { "gr",         telescope.lsp_references,                 desc = "References",                 nowait = true },
    -- { "gI",         telescope.lsp_implementations,            desc = "Goto Implementation" },
    -- { "gy",         telescope.lsp_type_definitions,           desc = "Goto T[y]pe Definition" },
    { "gD",         vim.lsp.buf.declaration,                  desc = "Goto Declaration" },
    { "K",          vim.lsp.buf.hover,                        desc = "Hover" },
    { "gK",         vim.lsp.buf.signature_help,               desc = "Signature Help",             has = "signatureHelp" },
    { "<c-k>",      vim.lsp.buf.signature_help,               mode = "i",                          desc = "Signature Help", has = "signatureHelp" },
    { "<leader>ca", vim.lsp.buf.code_action,                  desc = "Code Action",                mode = { "n", "v" },     has = "codeAction" },
    { "<leader>cc", vim.lsp.codelens.run,                     desc = "Run Codelens",               mode = { "n", "v" },     has = "codeLens" },
    { "<leader>cC", vim.lsp.codelens.refresh,                 desc = "Refresh & Display Codelens", mode = { "n" },          has = "codeLens" },
    { "<leader>cd", telescope.lsp_definitions,                desc = "Goto Definition",            mode = { "n" } },
    { "<leader>cD", telescope.lsp_references,                 desc = "References",                 mode = { "n" } },
    { "<leader>cI", "<cmd>Telescope lsp_implementations<cr>", desc = "Goto Implementation",        mode = { "n" } },
    { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", mode ={"n"}, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
    { "<leader>cr", vim.lsp.buf.rename,                       desc = "Rename",                     has = "rename" },
    { "<leader>cA", CoreUtil.lsp.action.source,               desc = "Source Action",              has = "codeAction" },
    { "]]", function() Snacks.words.jump(vim.v.count1) end, has = "documentHighlight",
      desc = "Next Reference", cond = function() return Snacks.words.is_enabled() end },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, has = "documentHighlight",
      desc = "Prev Reference", cond = function() return Snacks.words.is_enabled() end },
    { "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, has = "documentHighlight",
      desc = "Next Reference", cond = function() return Snacks.words.is_enabled() end },
    { "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, has = "documentHighlight",
      desc = "Prev Reference", cond = function() return Snacks.words.is_enabled() end },
    -- File
    {
      "<leader>fS",
      "<cmd>lua vim.lsp.buf.format()<CR><cmd>silent w!<CR>",
      desc = "Format and Save",
    },
  }

  return M._keys
end

---@param method string|string[]
function M.has(buffer, method)
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find("/") and method or "textDocument/" .. method
  local clients = CoreUtil.lsp.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    if client:supports_method(method) then
      return true
    end
  end
  return false
end

---@return LazyKeysLsp[]
function M.resolve(buffer)
  local Keys = require("lazy.core.handler.keys")
  if not Keys.resolve then
    return {}
  end
  local spec = M.get()
  local opts = CoreUtil.opts("nvim-lspconfig")
  local clients = CoreUtil.lsp.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
    vim.list_extend(spec, maps)
  end
  return Keys.resolve(spec)
end

function M.on_attach(_, buffer)
  local Keys = require("lazy.core.handler.keys")
  local keymaps = M.resolve(buffer)

  for _, keys in pairs(keymaps) do
    local has = not keys.has or M.has(buffer, keys.has)
    local cond = not (keys.cond == false or ((type(keys.cond) == "function") and not keys.cond()))

    if has and cond then
      ---@class LazyKeysBase
      local opts = Keys.opts(keys)
      opts.cond = nil
      opts.has = nil
      opts.silent = opts.silent ~= false
      opts.buffer = buffer
      vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
    end
  end
end

return M
