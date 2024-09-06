vim.api.nvim_set_keymap('n', ';d', '<Plug>(coc-definition)', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', ';r', '<Plug>(coc-references)', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', 'K', ':call CocActionAsync("doHover")<CR>', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>rn', '<Plug>(coc-rename)', { silent = true, noremap = true })

-- coc.nvim の設定を Lua 内で指定 (coc-settings.json に依存しない)
vim.g.coc_global_extensions = {
  'coc-tsserver',
  'coc-json',
  'coc-eslint',
  'coc-lua',
  '@yaegassy/coc-tailwindcss3',
}

local opts = { expr = true, noremap = true, silent = true }

-- coc.nvim の補完候補のナビゲートと確定のキーマッピング
vim.api.nvim_set_keymap('i', '<C-p>', 'coc#pum#visible() ? coc#pum#prev(1) : "<C-p>"', opts)
vim.api.nvim_set_keymap('i', '<C-n>', 'coc#pum#visible() ? coc#pum#next(1) : "<C-n>"', opts)
vim.api.nvim_set_keymap('i', '<C-u>', 'coc#pum#visible() ? "<C-u>" : coc#scroll(1)', opts)
vim.api.nvim_set_keymap('i', '<C-d>', 'coc#pum#visible() ? "<C-d>" : coc#scroll(-1)', opts)

-- Tabで補完を確定またはスニペットをジャンプ
vim.api.nvim_set_keymap(
  'i',
  '<Tab>',
  'pumvisible() ? coc#_select_confirm() : v:lua.check_backspace() ? "<Tab>" : coc#refresh()',
  opts
)

-- Shift+Tab でスニペットを逆方向にジャンプ
vim.api.nvim_set_keymap('i', '<S-Tab>', 'coc#pum#visible() ? coc#_select_confirm() : "<S-Tab>"', opts)

-- Enter で補完を確定
vim.api.nvim_set_keymap('i', '<CR>', 'pumvisible() ? coc#pum#confirm() : "<CR>"', opts)

-- 診断の移動
vim.api.nvim_set_keymap('n', '[g', '<Plug>(coc-diagnostic-prev)', { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', ']g', '<Plug>(coc-diagnostic-next)', { silent = true, noremap = true })

-- 保存時に自動でコードフォーマット
-- vim.api.nvim_create_autocmd('BufWritePre', {
--   pattern = '*',
--   command = 'silent! CocCommand editor.action.formatDocument',
-- })
