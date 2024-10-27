---------------------------------------------------------------------------------------------------+
-- Commands \ Modes | Normal | Insert | Command | Visual | Select | Operator | Terminal | Lang-Arg |
-- ================================================================================================+
-- map  / noremap   |    @   |   -    |    -    |   @    |   @    |    @     |    -     |    -     |
-- nmap / nnoremap  |    @   |   -    |    -    |   -    |   -    |    -     |    -     |    -     |
-- map! / noremap!  |    -   |   @    |    @    |   -    |   -    |    -     |    -     |    -     |
-- imap / inoremap  |    -   |   @    |    -    |   -    |   -    |    -     |    -     |    -     |
-- cmap / cnoremap  |    -   |   -    |    @    |   -    |   -    |    -     |    -     |    -     |
-- vmap / vnoremap  |    -   |   -    |    -    |   @    |   @    |    -     |    -     |    -     |
-- xmap / xnoremap  |    -   |   -    |    -    |   @    |   -    |    -     |    -     |    -     |
-- smap / snoremap  |    -   |   -    |    -    |   -    |   @    |    -     |    -     |    -     |
-- omap / onoremap  |    -   |   -    |    -    |   -    |   -    |    @     |    -     |    -     |
-- tmap / tnoremap  |    -   |   -    |    -    |   -    |   -    |    -     |    @     |    -     |
-- lmap / lnoremap  |    -   |   @    |    @    |   -    |   -    |    -     |    -     |    @     |
---------------------------------------------------------------------------------------------------+

-- ターミナルモードでインサートモードからEscでノーマルモードに
vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true })

-- 論理行と物理行の移動を入れ替え
vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', '<Down>', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', '<Up>', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', 'gj', 'j', { noremap = true })
vim.api.nvim_set_keymap('n', 'gk', 'k', { noremap = true })

-- リーダーキーの設定
vim.g.mapleader = ' '
vim.api.nvim_set_keymap('n', '<Space>', '<Nop>', { noremap = true })

-- インサートモード中の移動をEmacs風に
vim.api.nvim_set_keymap('i', '<C-p>', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-p>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Down>', { noremap = true })

-- Split window
vim.api.nvim_set_keymap('n', 'vs', ':vsplit<CR><C-w>w', { noremap = true })

--  va"をvi2"に
for _, quote in ipairs { '"', "'", '`' } do
  vim.keymap.set({ 'x', 'o' }, 'a' .. quote, '2i' .. quote)
end

---- VSCode設定
-- Esc
vim.keymap.set({ 'n', 'v', 's', 'o' }, '<C-[>', '<Esc>')

-- 定義ジャンプ
vim.keymap.set('n', ';d', "<Cmd>call VSCodeNotify('editor.action.goToDeclaration')<CR>")

-- バック
vim.keymap.set('n', '<C-o>', "<Cmd>call VSCodeNotify('workbench.action.navigateBack')<CR>")

-- 前のタブに移動
vim.keymap.set('n', 'gb', "<Cmd>call VSCodeNotify('workbench.action.previousEditor')<CR>")

-- ファイラを開く
vim.keymap.set('n', '<leader>e', "<Cmd>call VSCodeNotify('workbench.view.explorer')<CR>")
