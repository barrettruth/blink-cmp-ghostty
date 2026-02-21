local M = {}

function M.check()
  vim.health.start('blink-cmp-ghostty')

  local ok = pcall(require, 'blink.cmp')
  if ok then
    vim.health.ok('blink.cmp is installed')
  else
    vim.health.error('blink.cmp is not installed')
  end

  local bin = vim.fn.exepath('ghostty')
  if bin ~= '' then
    vim.health.ok('ghostty executable found: ' .. bin)
  else
    vim.health.error('ghostty executable not found')
    return
  end

  local result = vim.system({ 'ghostty', '+show-config', '--docs' }):wait()
  if result.code == 0 and result.stdout and result.stdout ~= '' then
    vim.health.ok('ghostty +show-config --docs produces output')
  else
    vim.health.warn(
      'ghostty +show-config --docs failed (config key documentation will be unavailable)'
    )
  end

  local source = require('blink-cmp-ghostty')
  local path = source.bash_completion_path()
  if not path then
    vim.health.warn('could not resolve bash completion path (enum completions will be unavailable)')
    return
  end
  local fd = io.open(path, 'r')
  if fd then
    fd:close()
    vim.health.ok('bash completion file found: ' .. path)
  else
    vim.health.warn(
      'bash completion file not found at ' .. path .. ' (enum completions will be unavailable)'
    )
  end
end

return M
