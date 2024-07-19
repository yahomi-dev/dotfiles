local lint = require('lint')

lint.linters_by_ft = {
  javascript = { 'eslint_d' },
  typescript = { 'eslint_d' },
  lua = { 'luacheck' },
  php = { 'php' },
}

-- 自動的に保存時にリンティングを実行する設定
vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('NvimLint', { clear = true }),
  pattern = '*',
  callback = function()
    require('lint').try_lint()
  end,
})