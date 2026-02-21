---@class blink-cmp-ghostty : blink.cmp.Source
local M = {}

---@type blink.cmp.CompletionItem[]?
local keys_cache = nil
---@type table<string, string[]>?
local enums_cache = nil

function M.new()
  return setmetatable({}, { __index = M })
end

---@return boolean
function M.enabled()
  return vim.bo.filetype == 'ghostty'
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

---@return string?
function M.bash_completion_path()
  local bin = vim.fn.exepath('ghostty')
  if bin == '' then
    return nil
  end
  local real = vim.uv.fs_realpath(bin)
  if not real then
    return nil
  end
  local prefix = real:match('(.*)/bin/ghostty$')
  if not prefix then
    return nil
  end
  return prefix .. '/share/bash-completion/completions/ghostty.bash'
end

---@return table<string, string[]>
local function parse_enums()
  local path = M.bash_completion_path()
  if not path then
    return {}
  end
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
