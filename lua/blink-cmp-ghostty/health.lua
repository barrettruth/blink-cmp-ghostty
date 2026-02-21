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

  local real = vim.uv.fs_realpath(bin)
  if not real then
    vim.health.warn('could not resolve ghostty symlink (enum completions will be unavailable)')
    return
  end
  local prefix = real:match('(.*)/bin/ghostty$')
  if not prefix then
    vim.health.warn(
      'ghostty binary is not in a standard bin/ directory (enum completions will be unavailable)'
    )
    return
  end
  local path = prefix .. '/share/bash-completion/completions/ghostty.bash'
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
