return {
  'tami5/lspsaga.nvim',
  config = function()
    require('lspsaga').setup()

    vim.api.nvim_create_autocmd({ 'CursorHold' }, {
      pattern = { '*' },
      callback = function()
        require('lspsaga.diagnostic').show_cursor_diagnostics()
      end
    })

    vim.api.nvim_create_autocmd({ 'FileType' }, {
      pattern = { 'typescript', 'typescriptreact', 'typescript.tsx' },
      callback = function()
        vim.keymap.set({ 'n' }, '<Plug>(lsp)f', function()
          vim.cmd([[EslintFixAll]])
          vim.lsp.buf.format({ name = 'null-ls' })
        end)
      end,
    })

    local function show_documentation()
      local ft = vim.opt.filetype._value
      if ft == 'vim' or ft == 'help' then
        vim.cmd([[execute 'h ' . expand('<cword>') ]])
      else
        require('lspsaga.hover').render_hover_doc()
      end
    end

    -- key maps
    vim.keymap.set({ 'n' }, 'K', show_documentation)
    vim.keymap.set({ 'n' }, 'zq', '<Cmd>Telescope diagnostics<CR>')
    vim.keymap.set({ 'n' }, ',[', require('lspsaga.diagnostic').navigate('next'))
    vim.keymap.set({ 'n' }, ',]', require('lspsaga.diagnostic').navigate('prev'))
    vim.keymap.set({ 'n' }, 'zi', '<Cmd>Telescope lsp_implementations<CR>')
    vim.keymap.set({ 'n' }, 'zt', '<Cmd>Telescope lsp_type_definitions<CR>')
    vim.keymap.set({ 'n' }, 'zr', '<Cmd>Telescope lsp_references<CR>')

  end
}
