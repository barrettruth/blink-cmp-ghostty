---@class blink-cmp-ghostty : blink.cmp.Source
local M = {}

---@type blink.cmp.CompletionItem[]?
local keys_cache = nil
---@type table<string, string[]>?
local enums_cache = nil
local loading = false
---@type {ctx: blink.cmp.Context, callback: fun(response: blink.cmp.CompletionResponse)}[]
local pending = {}

function M.new()
  return setmetatable({}, { __index = M })
end

---@return boolean
function M.enabled()
  return vim.bo.filetype == 'ghostty'
end

---@param stdout string
---@return blink.cmp.CompletionItem[]
local function parse_keys(stdout)
  local Kind = require('blink.cmp.types').CompletionItemKind
  local items = {}
  local doc_lines = {}

  for line in (stdout .. '\n'):gmatch('(.-)\n') do
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
local function respond(ctx, callback)
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
      return
    end
    callback({ items = {} })
  else
    callback({
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = keys_cache,
    })
  end
end

---@param ctx blink.cmp.Context
---@param callback fun(response: blink.cmp.CompletionResponse)
---@return fun()
function M:get_completions(ctx, callback)
  if keys_cache then
    respond(ctx, callback)
    return function() end
  end

  pending[#pending + 1] = { ctx = ctx, callback = callback }
  if not loading then
    loading = true
    vim.system({ 'ghostty', '+show-config', '--docs' }, {}, function(result)
      vim.schedule(function()
        keys_cache = parse_keys(result.stdout or '')
        enums_cache = parse_enums()
        loading = false
        for _, p in ipairs(pending) do
          respond(p.ctx, p.callback)
        end
        pending = {}
      end)
    end)
  end
  return function() end
end

return M
