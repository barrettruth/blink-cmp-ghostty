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
local function parse_enums(content)
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
  if not keys_cache or not enums_cache then
    return
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
    local config_out, enums_content
    local remaining = 2

    local function on_all_done()
      remaining = remaining - 1
      if remaining > 0 then
        return
      end
      vim.schedule(function()
        keys_cache = parse_keys(config_out)
        enums_cache = parse_enums(enums_content)
        loading = false
        for _, p in ipairs(pending) do
          respond(p.ctx, p.callback)
        end
        pending = {}
      end)
    end

    vim.system({ 'ghostty', '+show-config', '--docs' }, {}, function(result)
      config_out = result.stdout or ''
      on_all_done()
    end)

    local path = M.bash_completion_path()
    if not path then
      enums_content = ''
      on_all_done()
    else
      vim.uv.fs_open(path, 'r', 438, function(err, fd)
        if err or not fd then
          enums_content = ''
          on_all_done()
          return
        end
        vim.uv.fs_fstat(fd, function(err2, stat)
          if err2 or not stat then
            vim.uv.fs_close(fd)
            enums_content = ''
            on_all_done()
            return
          end
          vim.uv.fs_read(fd, stat.size, 0, function(err3, data)
            vim.uv.fs_close(fd)
            enums_content = data or ''
            on_all_done()
          end)
        end)
      end)
    end
  end
  return function() end
end

return M
