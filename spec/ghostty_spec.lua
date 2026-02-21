local helpers = require('spec.helpers')

local CONFIG_DOCS = table.concat({
  '# The font family to use.',
  '# This can be a comma-separated list of font families.',
  'font-family = default',
  '',
  '# The font size in points.',
  'font-size = 12',
  '',
  '# The cursor style.',
  'cursor-style = block',
  '',
}, '\n')

local BASH_COMPLETION = table.concat({
  '      --cursor-style) mapfile -t COMPREPLY < <( compgen -W "block bar underline" -- "$cur" ); _add_spaces ;;',
  '      --font-style) mapfile -t COMPREPLY < <( compgen -W "normal italic" -- "$cur" ); _add_spaces ;;',
}, '\n')

local function mock_system()
  local original_system = vim.system
  local original_schedule = vim.schedule
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.system = function(cmd, _, on_exit)
    if cmd[1] == 'ghostty' then
      local result = { stdout = CONFIG_DOCS, code = 0 }
      if on_exit then
        on_exit(result)
        return {}
      end
      return {
        wait = function()
          return result
        end,
      }
    end
    local result = { stdout = '', code = 1 }
    if on_exit then
      on_exit(result)
      return {}
    end
    return {
      wait = function()
        return result
      end,
    }
  end
  vim.schedule = function(fn)
    fn()
  end
  return function()
    vim.system = original_system
    vim.schedule = original_schedule
  end
end

local function mock_enums()
  local original_exepath = vim.fn.exepath
  local original_realpath = vim.uv.fs_realpath
  local original_open = io.open

  vim.fn.exepath = function(name)
    if name == 'ghostty' then
      return '/mock/bin/ghostty'
    end
    return original_exepath(name)
  end
  vim.uv.fs_realpath = function(path)
    if path == '/mock/bin/ghostty' then
      return '/mock/bin/ghostty'
    end
    return original_realpath(path)
  end
  -- selene: allow(incorrect_standard_library_use)
  io.open = function(path, mode)
    if path:match('ghostty%.bash$') then
      return {
        read = function()
          return BASH_COMPLETION
        end,
        close = function() end,
      }
    end
    return original_open(path, mode)
  end

  return function()
    vim.fn.exepath = original_exepath
    vim.uv.fs_realpath = original_realpath
    -- selene: allow(incorrect_standard_library_use)
    io.open = original_open
  end
end

describe('blink-cmp-ghostty', function()
  local restores = {}

  before_each(function()
    package.loaded['blink-cmp-ghostty'] = nil
  end)

  after_each(function()
    for _, fn in ipairs(restores) do
      fn()
    end
    restores = {}
  end)

  describe('enabled', function()
    it('returns true for ghostty filetype', function()
      local bufnr = helpers.create_buffer({}, 'ghostty')
      local source = require('blink-cmp-ghostty')
      assert.is_true(source.enabled())
      helpers.delete_buffer(bufnr)
    end)

    it('returns false for other filetypes', function()
      local bufnr = helpers.create_buffer({}, 'lua')
      local source = require('blink-cmp-ghostty')
      assert.is_false(source.enabled())
      helpers.delete_buffer(bufnr)
    end)
  end)

  describe('get_completions', function()
    it('returns config keys before =', function()
      restores[#restores + 1] = mock_system()
      restores[#restores + 1] = mock_enums()
      local source = require('blink-cmp-ghostty').new()
      local items
      source:get_completions({ line = 'font', cursor = { 1, 4 } }, function(response)
        items = response.items
      end)
      assert.is_not_nil(items)
      assert.equals(3, #items)
      for _, item in ipairs(items) do
        assert.equals(10, item.kind)
      end
    end)

    it('includes documentation from config docs', function()
      restores[#restores + 1] = mock_system()
      restores[#restores + 1] = mock_enums()
      local source = require('blink-cmp-ghostty').new()
      local items
      source:get_completions({ line = '', cursor = { 1, 0 } }, function(response)
        items = response.items
      end)
      local font_family = vim.iter(items):find(function(item)
        return item.label == 'font-family'
      end)
      assert.is_not_nil(font_family)
      assert.is_not_nil(font_family.documentation)
      assert.is_truthy(font_family.documentation.value:find('font family'))
    end)

    it('returns enum values after =', function()
      restores[#restores + 1] = mock_system()
      restores[#restores + 1] = mock_enums()
      local source = require('blink-cmp-ghostty').new()
      local items
      source:get_completions({ line = 'cursor-style = ', cursor = { 1, 15 } }, function(response)
        items = response.items
      end)
      assert.is_not_nil(items)
      assert.equals(3, #items)
      for _, item in ipairs(items) do
        assert.equals(20, item.kind)
      end
    end)

    it('returns empty after = for unknown key', function()
      restores[#restores + 1] = mock_system()
      restores[#restores + 1] = mock_enums()
      local source = require('blink-cmp-ghostty').new()
      local items
      source:get_completions({ line = 'font-family = ', cursor = { 1, 14 } }, function(response)
        items = response.items
      end)
      assert.equals(0, #items)
    end)

    it('returns a cancel function', function()
      restores[#restores + 1] = mock_system()
      restores[#restores + 1] = mock_enums()
      local source = require('blink-cmp-ghostty').new()
      local cancel = source:get_completions({ line = '', cursor = { 1, 0 } }, function() end)
      assert.is_function(cancel)
    end)
  end)
end)
