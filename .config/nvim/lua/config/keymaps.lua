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
vim.api.nvim_set_keymap('v', 'j', 'gj', { noremap = true })
vim.api.nvim_set_keymap('v', 'k', 'gk', { noremap = true })
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

--検索時に画面中央になるように
vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')

-- CRの入力をLFに
vim.api.nvim_set_keymap('i', '<C-m>', '<CR>', { noremap = true })

-- New tab
vim.api.nvim_set_keymap('n', 'te', ':tabedit', { noremap = true })

-- tabの前送り
vim.api.nvim_set_keymap('n', 'gb', 'gT', { noremap = true })

-- Split window
vim.api.nvim_set_keymap('n', 'vs', ':vsplit<CR><C-w>w', { noremap = true })

--  va"をvi2"に
for _, quote in ipairs { '"', "'", '`' } do
  vim.keymap.set({ 'x', 'o' }, 'a' .. quote, '2i' .. quote)
end

-- フルパスをクリップボードにコピー
vim.keymap.set('n', '<leader>Y', function()
  local path = vim.fn.expand('%:p') -- フルパス取得
  vim.fn.setreg('+', path) -- クリップボードにコピー
  vim.notify('Copied: ' .. path, vim.log.levels.INFO) -- 通知
end, { desc = 'Copy full file path to clipboard' })

vim.keymap.set('n', '<leader>y', function()
  -- 現在開いているファイルのフルパスを取得
  local full_path = vim.fn.expand('%:p')

  -- Gitリポジトリのルートを取得（失敗したらnil）
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]

  -- Gitのルートディレクトリが取得でき、かつファイルがその配下にある場合
  local final_path = full_path
  if git_root and vim.v.shell_error == 0 then
    local git_root_normalized = git_root:gsub('/$', '') -- 末尾の `/` を削除
    if full_path:find(git_root_normalized, 1, true) == 1 then
      -- Gitルートからの相対パスを取得
      final_path = full_path:sub(#git_root_normalized + 2) -- `/` 分を考慮
    end
  end

  -- クリップボードにコピー
  vim.fn.setreg('+', final_path)

  -- 通知を表示
  vim.notify('Copied: ' .. final_path, vim.log.levels.INFO)
end, { desc = 'Copy Git-relative or full file path to clipboard' })
