return {
  'jose-elias-alvarez/null-ls.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local null_ls = require('null-ls')

    -- vscodeでの設定との差異があるので直接指定
    local prettier_args = {
      '--print-width', '120',
      '--trailing-comma', 'none',
      '--single-quote',
      '--arrow-parens', 'avoid',
    }

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.prettier.with({
          filetypes = { 'javascript' },
          extra_args = prettier_args
        }),
      },
      command = 'prettier',
    })

    vim.api.nvim_set_keymap('n', '<leader>fm', '<cmd>lua vim.lsp.buf.format()<CR>',
      { noremap = true }
    )

  end
}
