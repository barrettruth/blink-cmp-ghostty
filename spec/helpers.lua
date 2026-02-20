local plugin_dir = vim.fn.getcwd()
vim.opt.runtimepath:prepend(plugin_dir)

if not package.loaded['blink.cmp.types'] then
  package.loaded['blink.cmp.types'] = {
    CompletionItemKind = {
      Text = 1,
      Method = 2,
      Function = 3,
      Constructor = 4,
      Field = 5,
      Variable = 6,
      Class = 7,
      Interface = 8,
      Module = 9,
      Property = 10,
      Unit = 11,
      Value = 12,
      Enum = 13,
      Keyword = 14,
      Snippet = 15,
      Color = 16,
      File = 17,
      Reference = 18,
      Folder = 19,
      EnumMember = 20,
      Constant = 21,
      Struct = 22,
      Event = 23,
      Operator = 24,
      TypeParameter = 25,
    },
  }
end

local M = {}

function M.create_buffer(lines, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or {})
  if filetype then
    vim.api.nvim_set_option_value('filetype', filetype, { buf = bufnr })
  end
  vim.api.nvim_set_current_buf(bufnr)
  return bufnr
end

function M.delete_buffer(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

return M
