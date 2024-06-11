return {
  vim.api.nvim_create_autocmd({ 'CursorHold' }, {
    pattern = { '*' },
    callback = function()
      require('lspsaga.diagnostic').show_cursor_diagnostics()
    end
  })
}
