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

vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', '<Down>', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', '<Up>', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', 'gj', 'j', { noremap = true })
vim.api.nvim_set_keymap('n', 'gk', 'k', { noremap = true })

vim.api.nvim_set_keymap('n', '<Space>', '<Nop>', { noremap = true })

-- Emacs like keybinding
vim.api.nvim_set_keymap('i', '<C-p>', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-p>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Down>', { noremap = true })

-- CRの入力をLFに
vim.api.nvim_set_keymap('i', '<C-m>', '<CR>', { noremap = true })

-- New tab
vim.api.nvim_set_keymap('n', 'te', ':tabedit', { noremap = true })

-- tabの前送り
vim.api.nvim_set_keymap('n', 'gb', 'gT', { noremap = true })

-- Split window
vim.api.nvim_set_keymap('n', 'vs', ':vsplit<Return><C-w>w', { noremap = true })

-- switch case
vim.api.nvim_set_keymap('x', '<Space>j', ':s/\\<\\@!\\([A-Z]\\)/-\\l\\1/g<CR>', { noremap = true })

--  va"をvi2"に
for _, quote in ipairs { '"', "'", '`' } do
  vim.keymap.set({ 'x', 'o' }, 'a' .. quote, '2i' .. quote)
end
