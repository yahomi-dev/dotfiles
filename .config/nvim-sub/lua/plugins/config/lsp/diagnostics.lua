local diagnostic_config = {
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
}

return diagnostic_config
