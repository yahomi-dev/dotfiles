vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    spacing = 2,
    format = function(diagnostic)
      local code = diagnostic.code or ''
      local source = diagnostic.source or ''
      return string.format('%s (%s: %s)', diagnostic.message, source, code)
    end,
  },
  float = {
    source = 'always',
    border = 'rounded',
  },
})

local signs = { Error = '', Warn = '', Hint = '󰌶', Info = '' }
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Set diagnostic border style
require('lspconfig.ui.windows').default_options.border = 'rounded'
