---@class blink-cmp-ghostty : blink.cmp.Source
local M = {}

---@type blink.cmp.CompletionItem[]?
local keys_cache = nil
---@type table<string, string[]>?
local enums_cache = nil

function M.new()
  return setmetatable({}, { __index = M })
end

local ghostty_config_dirs = {
  vim.fn.expand('$XDG_CONFIG_HOME/ghostty'),
  vim.fn.expand('$HOME/.config/ghostty'),
  '/etc/ghostty',
}

---@return boolean
function M.enabled()
  if vim.bo.filetype == 'ghostty' then
    return true
  end
  if vim.bo.filetype ~= 'config' and vim.bo.filetype ~= '' then
    return false
  end
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    return false
  end
  local real = vim.uv.fs_realpath(path) or path
  for _, dir in ipairs(ghostty_config_dirs) do
    if real:find(dir, 1, true) == 1 then
      return true
    end
  end
  return false
end

---@return blink.cmp.CompletionItem[]
local function parse_keys()
  local Kind = require('blink.cmp.types').CompletionItemKind
  local result = vim.system({ 'ghostty', '+show-config', '--docs' }):wait()
  local items = {}
  local doc_lines = {}

  for line in ((result.stdout or '') .. '\n'):gmatch('(.-)\n') do
    if line:match('^#') then
      local stripped = line:gsub('^# ?', '')
      doc_lines[#doc_lines + 1] = stripped
    else
      local key = line:match('^([a-z][a-z0-9-]*)%s*=')
      if key then
        local doc = #doc_lines > 0 and table.concat(doc_lines, '\n') or nil
        items[#items + 1] = {
          label = key,
          kind = Kind.Property,
          documentation = doc and { kind = 'markdown', value = doc } or nil,
        }
      end
      doc_lines = {}
    end
  end
  return items
end

---@return table<string, string[]>
local function parse_enums()
  local bin = vim.fn.exepath('ghostty')
  if bin == '' then
    return {}
  end
  local real = vim.uv.fs_realpath(bin)
  if not real then
    return {}
  end
  local prefix = real:match('(.*)/bin/ghostty$')
  if not prefix then
    return {}
  end
  local path = prefix .. '/share/bash-completion/completions/ghostty.bash'
  local fd = io.open(path, 'r')
  if not fd then
    return {}
  end
  local content = fd:read('*a')
  fd:close()

  local enums = {}
  for key, values in content:gmatch('%-%-([a-z][a-z0-9-]*)%) [^\n]* compgen %-W "([^"]+)"') do
    local vals = {}
    for v in values:gmatch('%S+') do
      vals[#vals + 1] = v
    end
    if #vals > 0 then
      enums[key] = vals
    end
  end
  return enums
end

---@param ctx blink.cmp.Context
---@param callback fun(response: blink.cmp.CompletionResponse)
---@return fun()
function M:get_completions(ctx, callback)
  if not keys_cache then
    keys_cache = parse_keys()
    enums_cache = parse_enums()
  end

  local line = ctx.line
  local col = ctx.cursor[2]
  local eq_pos = line:find('=')

  if eq_pos and col > eq_pos then
    local key = vim.trim(line:sub(1, eq_pos - 1))
    local vals = enums_cache[key]
    if vals then
      local Kind = require('blink.cmp.types').CompletionItemKind
      local items = {}
      for _, v in ipairs(vals) do
        items[#items + 1] = {
          label = v,
          kind = Kind.EnumMember,
          filterText = v,
        }
      end
      callback({
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = items,
      })
      return function() end
    end
    callback({ items = {} })
  else
    callback({
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = vim.deepcopy(keys_cache),
    })
  end
  return function() end
end

return M
